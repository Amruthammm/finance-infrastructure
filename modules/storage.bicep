// modules/storage.bicep

@description('Environment (dev, test, or prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string

@description('Location for the storage account')
param location string

@description('Tags for the storage account')
param tags object

// Storage account name based on environment
var storageAccountName = environment == 'prod' ? 'stfinanceprod' : 'stfinancenonprod'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: environment == 'prod' ? 'Standard_GRS' : 'Standard_LRS'  // GRS for prod, LRS for dev/test
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    // networkAcls: {
    //   bypass: 'AzureServices'
    //   defaultAction: 'Deny'  // Locked down by default
    // }
  }
}

// // Create blob service and container
// resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
//   parent: storageAccount
//   name: 'default'
//   properties: {
//     deleteRetentionPolicy: {
//       enabled: true
//       days: 7
//     }
//   }
// }

// resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
//   parent: blobService
//   name: 'finance'
//   properties: {
//     publicAccess: 'None'
//   }
// }

// Outputs
output storageAccountName string = storageAccount.name
//output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
