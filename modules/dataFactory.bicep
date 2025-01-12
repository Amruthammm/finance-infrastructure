// modules/dataFactory.bicep
param baseName string
param environment string
param location string
param tags object
param subnetId string  // For private endpoints
//param keyVaultId string           // Key Vault for storing secrets
//param cosmosDbId string          // Cosmos DB ID

var deploymentId = uniqueString(resourceGroup().id)
var dataFactoryName = 'adf-${baseName}-${environment}-${deploymentId}' 
var privateEndpointName = 'pe-${dataFactoryName}'


// Data Factory
resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'    // Disable public access
    globalParameters: {}
    encryption: {
      identity: {
        userAssignedIdentity: ''  // Uses system-assigned identity
      }
      vaultBaseUrl: ''
      keyName: ''
      keyVersion: ''
    }
  }
}

// Create Managed Virtual Network first
resource managedVirtualNetwork 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
  parent: dataFactory
  name: 'default'
  properties: {}
}

// Key Vault Linked Service
// resource keyVaultLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
//   parent: dataFactory
//   name: 'KeyVaultLinkedService'
//   properties: {
//     type: 'AzureKeyVault'
//     typeProperties: {
//       baseUrl: 'https://${reference(keyVaultId, '2023-02-01').vaultUri}'
//     }
//   }
// }


// Cosmos DB Linked Service
// resource cosmosDbLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
//   parent: dataFactory
//   name: 'CosmosDbLinkedService'
//   properties: {
//     type: 'CosmosDb'
//     typeProperties: {
//       connectionString: {
//         type: 'AzureKeyVaultSecret'
//         store: {
//           referenceName: keyVaultLinkedService.name
//           type: 'LinkedServiceReference'
//         }
//         secretName: 'CosmosDbConnectionString'
//       }
//     }
//     connectVia: {
//       referenceName: 'AutoResolveIntegrationRuntime'
//       type: 'IntegrationRuntimeReference'
//     }
//   }
// }

// Auto Resolve Integration Runtime with Managed VNet
resource autoResolveRuntime 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  parent: dataFactory
  name: 'AutoResolveIntegrationRuntime'
  dependsOn: [
    managedVirtualNetwork
  ]
  properties: {
    type: 'Managed'
    managedVirtualNetwork: {
      type: 'ManagedVirtualNetworkReference'
      referenceName: managedVirtualNetwork.name
    }
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
        dataFlowProperties: {
          computeType: 'General'
          coreCount: 8
          timeToLive: 10
        }
      }
    }
  }
}

// Managed Private Endpoint for SQL
resource managedPrivateEndpointSQL 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  parent: managedVirtualNetwork
  name: 'SQL'
  properties: {
    privateLinkResourceId: subnetId
    groupId: 'sqlServer'
  }
}

// Private Endpoint
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: dataFactory.id
          groupIds: [
            'dataFactory'
          ]
        }
      }
    ]
  }
}

// Diagnostic Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${dataFactoryName}-diagnostics'
  scope: dataFactory
  properties: {
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'ActivityRuns'
        enabled: true
      }
      {
        category: 'PipelineRuns'
        enabled: true
      }
      {
        category: 'TriggerRuns'
        enabled: true
      }
      {
        category: 'SSISPackageEventMessages'
        enabled: true
      }
      {
        category: 'SSISPackageExecutableStatistics'
        enabled: true
      }
      {
        category: 'SSISPackageEventMessageContext'
        enabled: true
      }
      {
        category: 'SSISIntegrationRuntimeLogs'
        enabled: true
      }
    ]
  }
}

// Outputs
output dataFactoryName string = dataFactory.name
output dataFactoryId string = dataFactory.id
output principalId string = dataFactory.identity.principalId
output privateEndpointId string = privateEndpoint.id
