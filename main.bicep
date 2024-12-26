// main.bicep
targetScope = 'subscription'

@description('Environment (dev, test, or prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Location for all resources')
param location string = 'canadacentral'

// Common tags
var tags = {
  Environment: environment
  Application: 'Finance'
  ManagedBy: 'Bicep'
}
var resourceGroupName = 'rg-finance-${environment}'

// Create Resource Group
module rg 'modules/resourceGroup.bicep' = {
  name: 'resourceGroup-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
  }
}

// Deploy networking
// module networking 'modules/networking.bicep' = {
//   scope: resourceGroup('rg-finance-${environment}')
//   name: 'networking-deployment'
//   params: {
//     baseName: 'finance'
//     environment: environment
//     location: location
//     tags: tags
//   }
//   dependsOn: [
//     rg
//   ]
// }

// Deploy App Service
module appService 'modules/appService.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'appService-deployment'
  params: {
    baseName: 'finance' //Pass parameters to module
    environment: environment
    location: location
    tags: tags
    resourceGroupName: resourceGroupName
    //subnetId: networking.outputs.webAppSubnetId
  }
  dependsOn: [
   // networking
   rg
  ]
}

// Outputs
output resourceGroupName string = rg.outputs.resourceGroupName
//output vnetName string = networking.outputs.vnetName
output webAppName string = appService.outputs.webAppName
output webAppHostName string = appService.outputs.webAppHostName
