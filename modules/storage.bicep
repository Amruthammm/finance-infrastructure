// modules/storage.bicep
@description('Base name for the resources')
param baseName string

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
    allowBlobPublicAccess: true
    // minimumTlsVersion: 'TLS1_2'
    // allowBlobPublicAccess: false
    // supportsHttpsTrafficOnly: true
    

    // networkAcls: {
    //   bypass: 'AzureServices'
    //   defaultAction: 'Deny'  // Locked down by default
    // }
  }
}

// Create table service
resource tableService 'Microsoft.Storage/storageAccounts/tableServices@2023-01-01' = {
  parent: storageAccount
  name: 'default'
}

// Create table
resource table 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-01-01' = {
  parent: tableService
  name: 'customertable'  // Your table name
}

//Added images into blob service
// // // Create blob service and container
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
//   name: 'images'
//   properties: {
//      publicAccess: 'Container'
//    // publicAccess: 'None'
//   }
// }

// Outputs
output storageAccountName string = storageAccount.name
//output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
