// modules/functionApp.bicep
param baseName string
param environment string
param location string 
param tags object
//param subnetId string //if used premium get param from main 



var storageAccountName = take('stfunc${baseName}${environment}${uniqueString(resourceGroup().id)}', 24)
var functionAppName = 'func-${baseName}-${environment}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}


// Consumption plan (serverless)
resource hostingPlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: 'asp-${functionAppName}'
  location: location
  sku: {
    name: 'Y1'
  }
}

resource functionApp 'Microsoft.Web/sites@2023-01-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${az.environment().suffixes.storage};AccountKey=${listKeys(storageAccount.id, '2023-01-01').keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
      ]
    }
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
