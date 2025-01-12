// modules/managedIdentity.bicep
param baseName string
param environment string
param location string
param tags object
param subnetId string    // Added subnet parameter

var managedIdentityName = 'id-${baseName}-${environment}'
var privateEndpointName = 'pe-${managedIdentityName}'

// User Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

// Private Endpoint for Managed Identity
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId  // Reference to shared subnet
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: managedIdentity.id
          groupIds: [
            'userAssignedIdentity'
          ]
        }
      }
    ]
  }
}

// Diagnostic settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${managedIdentityName}-diagnostics'
  scope: managedIdentity
  properties: {
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Outputs
output managedIdentityName string = managedIdentity.name
output managedIdentityId string = managedIdentity.id
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
output privateEndpointId string = privateEndpoint.id

//Function App accessing Storage Account: Function App with System Identity
// resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
//   name: 'func-${baseName}-${environment}'
//   kind: 'functionapp'
//   identity: {
//     type: 'SystemAssigned'    // Enable system identity
//   }
// }

// // Give Function App access to Storage
// resource storageBlobRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(functionApp.id, storageAccount.id, 'StorageBlobDataContributor')
//   scope: storageAccount    // Scope to storage account
//   properties: {
//     principalId: functionApp.identity.principalId    // Use function app's identity
//     roleDefinitionId: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe' // Storage Blob Data Contributor role
//   }
// }







