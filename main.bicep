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

// Deploy networking only
module networking 'modules/networking.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'networking-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
  }
  dependsOn: [
    rg
  ]
}

// Deploy App Service with VNet integration
module appService 'modules/appService.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'appService-deployment'
  params: {
    baseName: 'finance' //Pass parameters to module
    environment: environment
    location: location
    tags: tags
    resourceGroupName: resourceGroupName
    subnetId: networking.outputs.appSubnetId  // Connect to the app subnet    
  }
  dependsOn: [
   rg   
  ]
}

module cosmosDb 'modules/cosmosDb.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'cosmos-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
    subnetId: networking.outputs.dataSubnetId
  }
  dependsOn: [
    rg
  ]
}

module keyVault 'modules/keyvault.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'keyvault-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
    subnetId: networking.outputs.dataSubnetId
  }
}

// Outputs
output resourceGroupName string = rg.outputs.resourceGroupName
output vnetName string = networking.outputs.vnetName
output defaultSubnetId string = networking.outputs.defaultSubnetId
output appSubnetId string = networking.outputs.appSubnetId
output webAppName string = appService.outputs.webAppName
output webAppHostName string = appService.outputs.webAppHostName
output cosmosAccountName string = cosmosDb.outputs.accountName
output keyVaultName string = keyVault.outputs.keyVaultName
