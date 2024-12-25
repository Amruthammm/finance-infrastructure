// main.bicep
targetScope = 'subscription'

// Parameters
@description('Environment (dev, test, or prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Location for all resources')
param location string = 'eastus'

// Common tags
var tags = {
  Environment: environment
  Application: 'Finance'
  ManagedBy: 'Bicep'
}

// Create Resource Group using the module
module rg 'modules/resourceGroup.bicep' = {
  name: 'resourceGroup-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
  }
}

module storage 'modules/storage.bicep' = {
  scope: resourceGroup('rg-finance-${environment}') 
  name: 'storage-deployment'
  params: {
    environment: environment
    location: location
    tags: tags
  }
  dependsOn: [
    rg
  ]
}

// // Deploy App Service into the resource group
// module appService 'modules/appService.bicep' = {
//   scope: resourceGroup(rg.outputs.resourceGroupName)  // Reference the created resource group
//   name: 'appService-deployment'
//   params: {
//     baseName: 'finance'
//     environment: environment
//     location: location
//     tags: tags
//   }
//   dependsOn: [
//     rg  // Make sure resource group exists before deploying app service
//   ]
// }

// Outputs
output resourceGroupName string = rg.outputs.resourceGroupName
output storageAccountName string = storage.outputs.storageAccountName
// output webAppName string = appService.outputs.webAppName
// output webAppHostName string = appService.outputs.webAppHostName
