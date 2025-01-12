// modules/managedIdentity.bicep
param baseName string
param environment string
param location string
param tags object

var managedIdentityName = 'id-${baseName}-${environment}'
var roleNameReader = 'acdd72a7-3385-48ef-bd42-f606fba81ae7'  // Reader role
var roleNameContributor = 'b24988ac-6180-42a0-ab88-20f7382dd24c'  // Contributor role
var roleNameKeyVaultSecretsUser = '4633458b-17de-408a-b874-0445c86b69e6'  // Key Vault Secrets User
var roleNameStorageBlobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'  // Storage Blob Data Contributor

// User Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

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

// Role assignment at subscription level for Reader access
resource readerRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subscription().id, managedIdentity.id, roleNameReader)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleNameReader)
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Generic role definition reference for Key Vault Secrets User
resource keyVaultSecretsUserRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: roleNameKeyVaultSecretsUser
}

// Generic role definition reference for Storage Blob Data Contributor
resource storageBlobDataContributorRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: roleNameStorageBlobDataContributor
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

// Federated credentials for GitHub Actions (optional)
resource federatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: 'github-federated-credential'
  parent: managedIdentity
  properties: {
    audiences: [
      'api://AzureADTokenExchange'
    ]
    issuer: 'https://token.actions.githubusercontent.com'
    subject: 'repo:organization/repository:environment:Production'
  }
}

// Outputs
output managedIdentityName string = managedIdentity.name
output managedIdentityId string = managedIdentity.id
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
output tenantId string = tenant().tenantId





