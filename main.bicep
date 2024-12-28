// main.bicep
targetScope = 'subscription'

@description('Environment (dev, test, or prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'test'

@description('Location for all resources')
param location string = 'canadacentral'

param adminUsername string
@secure()
param adminPassword string

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

module functionApp 'modules/functionApp.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'functionapp-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
   // subnetId: networking.outputs.appSubnetId //Pass parameters to module if used premium plan 
  }
  dependsOn: [
    rg
  ]
}

module aks 'modules/aks.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'aks-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
    subnetId: networking.outputs.aksSubnetId
  }
  dependsOn: [
          rg
       ]
}
module containerApp 'modules/containerApp.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'containerapp-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
    subnetId: networking.outputs.containerAppSubnetId  
  }
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
module redis 'modules/redis.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'redis-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
    subnetId: networking.outputs.dataSubnetId
  }
}

// // VM Module
module virtualMachine 'modules/vm.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'vm-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
    subnetId: networking.outputs.vmSubnetId
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

 module dataFactory 'modules/dataFactory.bicep' = {
   scope: resourceGroup(resourceGroupName)
   name: 'adf-deployment'
   params: {
     baseName: 'finance'
     environment: environment
     location: location
     tags: tags
     subnetId: networking.outputs.dataSubnetId
     //keyVaultId: keyVault.outputs.keyVaultId    
     //cosmosDbId: cosmosDb.outputs.accountName
   }
 }

// Deploy Log Analytics first
module logAnalytics 'modules/logAnalytics.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'logs-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
  }
}

// Then App Insights using Log Analytics
module appInsights 'modules/appInsights.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'appinsights-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsId
  }
}

// Managed Identity
module managedIdentity 'modules/managedIdentity.bicep' = {
  scope: resourceGroup(resourceGroupName)
  name: 'identity-deployment'
  params: {
    baseName: 'finance'
    environment: environment
    location: location
    tags: tags
  }
}


// Outputs
output resourceGroupName string = rg.outputs.resourceGroupName
output vnetName string = networking.outputs.vnetName
output defaultSubnetId string = networking.outputs.defaultSubnetId
output appSubnetId string = networking.outputs.appSubnetId
output aksSubnetId string = networking.outputs.aksSubnetId
output vmName string = virtualMachine.outputs.vmName
output vmPrivateIP string = virtualMachine.outputs.privateIP
output dataFactoryName string = dataFactory.outputs.dataFactoryName
output redisHostName string = redis.outputs.redisHostName
output webAppName string = appService.outputs.webAppName
output webAppHostName string = appService.outputs.webAppHostName
output cosmosAccountName string = cosmosDb.outputs.accountName
output keyVaultName string = keyVault.outputs.keyVaultName
output logAnalyticsName string = logAnalytics.outputs.logAnalyticsName
output appInsightsName string = appInsights.outputs.appInsightsName
output managedIdentityName string = managedIdentity.outputs.managedIdentityName
