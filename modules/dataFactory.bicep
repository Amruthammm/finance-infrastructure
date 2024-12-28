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
    publicNetworkAccess: 'Enabled'    // Can be disabled after private endpoint setup
    globalParameters: {}
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

// Integration Runtime for VNet integration
resource integrationRuntime 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  parent: dataFactory
  name: 'VNetIntegrationRuntime'
  dependsOn: [
    managedVirtualNetwork // Add dependency on managed VNet
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
      }
    }
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

output dataFactoryName string = dataFactory.name
output dataFactoryId string = dataFactory.id
