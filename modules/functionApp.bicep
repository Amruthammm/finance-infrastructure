// modules/functionApp.bicep
param baseName string
param environment string
param location string 
param tags object
@description('Resource Group Name')
param resourceGroupName string
//param subnetId string //if used premium get param from main 



var deploymentId = uniqueString(resourceGroup().id)
var storageAccountName = take('stfunc${baseName}${environment}${deploymentId}', 24)
var functionAppName = take('func-${baseName}-${environment}-${deploymentId}', 24)

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

// Consumption plan (serverless)
resource hostingPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'plan-${functionAppName}'
  location: location
  tags: tags
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}


resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, '2023-01-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, '2023-01-01').keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: '1'
        }
        {
          name: 'WEBSITE_RESOURCE_GROUP'
          value: resourceGroupName
        }
      ]
    }
    httpsOnly: true
  }
}

//VNET not supported in consumption plan. Below is the app data subnet connection for function premium
// resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
//  name: hostingPlanName
//  location: location
//  tags: tags
//  sku: {
//    name: 'EP1'
//    tier: 'ElasticPremium'
//  }
//  properties: {
//    maximumElasticWorkerCount: 20
//  }
// }

// resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
//  name: functionAppName
//  location: location
//  tags: tags
//  kind: 'functionapp'
//  properties: {
//    serverFarmId: hostingPlan.id
//    virtualNetworkSubnetId: subnetId
//    siteConfig: {
//      vnetRouteAllEnabled: true
//      appSettings: [
//        {
//          name: 'AzureWebJobsStorage'
//          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
//        }
//        {
//          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
//          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
//        }
//        {
//          name: 'FUNCTIONS_EXTENSION_VERSION'
//          value: '~4'
//        }
//        {
//          name: 'FUNCTIONS_WORKER_RUNTIME'
//          value: 'dotnet'
//        }
//      ]
//    }
//  }
// }

output functionAppName string = functionApp.name
