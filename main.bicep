// main.bicep
targetScope = 'resourceGroup'

param environment string 

@description('Location for all resources')
param location string

param resourceGroupName string

param tags object 

param baseName string

@description('Network configuration')
param networkConfig object

// param adminUsername string
// @secure()
// param adminPassword string


// Deploy networking only
module networking 'modules/networking.bicep' = {  
  name: 'networking-deployment'
  params: {
    baseName: baseName
    environment: environment
    location: location
    tags: tags
    networkConfig: networkConfig
  } 
}

// // Deploy Log Analytics first
module logAnalytics 'modules/logAnalytics.bicep' = {  
  name: 'logs-deployment'
  params: {
    baseName: baseName
    environment: environment
    location: location
    tags: tags    
    subnetId: networking.outputs.sharedSubnetId
  }
}
// // Then App Insights using Log Analytics
module appInsights 'modules/appInsights.bicep' = {  
  name: 'appinsights-deployment'
  params: {
    baseName: baseName
    environment: environment
    location: location
    tags: tags
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsId    
  }
}
module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    baseName: baseName
    environment: environment
    location: location
    tags: tags
    subnetId: networking.outputs.dataSubnetId 
  }
}

// Deploy App Service with VNet integration
module appService 'modules/appService.bicep' = {
 name: 'appService-deployment'
 params: {
 baseName: baseName //Pass parameters to module
 environment: environment
 location: location
 tags: tags
 resourceGroupName: resourceGroupName
 storageAccountName: storage.outputs.storageAccountName
 subnetId: networking.outputs.webAppSubnetId  // Connect to the app subnet    
 logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsId
 appInsightsConnectionString: appInsights.outputs.connectionString
 appInsightsinstrumentationKey: appInsights.outputs.instrumentationKey
 }
}

 module functionApp 'modules/functionApp.bicep' = {  
 name: 'functionapp-deployment'
 params: {
  baseName: baseName
  environment: environment
  location: location
  tags: tags
  resourceGroupName: resourceGroupName
  subnetId: networking.outputs.functionSubnetId  //Pass parameters to module if used premium plan 
 }
 }

module aks 'modules/aks.bicep' = {  
 name: 'aks-deployment'
 params: {
  baseName: baseName
  environment: environment
  location: location
  tags: tags
  subnetId: networking.outputs.aksSubnetId
 }
}

 module containerApp 'modules/containerApp.bicep' = {
 name: 'containerapp-deployment'
params: {
 baseName: baseName
 environment: environment
 location: location
 tags: tags
 subnetId: networking.outputs.containerAppSubnetId
appInsightsConnectionString: appInsights.outputs.connectionString
}
}

module cosmosDb 'modules/cosmosDb.bicep' = {  
name: 'cosmos-deployment'
 params: {
  baseName: baseName
  environment: environment
  location: location
  tags: tags
  subnetId: networking.outputs.dataSubnetId
 }
}

module redis 'modules/redis.bicep' = {  
 name: 'redis-deployment'
 params: {
  baseName: 'finance'
  environment: environment
  location: location
  tags: tags
  subnetId: networking.outputs.dataSubnetId
 }
}

module dataFactory 'modules/dataFactory.bicep' = {   
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
module keyVault 'modules/keyvault.bicep' = {   
 name: 'keyvault-deployment'
 params: {
  baseName: 'finance'
  environment: environment
  location: location
  tags: tags
  subnetId: networking.outputs.sharedSubnetId
 }
}

//teju

// // VM Module
// // module virtualMachine 'modules/vm.bicep' = {  
//   name: 'vm-deployment'
//   params: {
//     baseName: 'finance'
//     environment: environment
//     location: location
//     tags: tags
//     subnetId: networking.outputs.vmSubnetId
//     adminUsername: adminUsername
//     adminPassword: adminPassword
//   }
// }


// // Managed Identity
// module managedIdentity 'modules/managedIdentity.bicep' = { 
//   name: 'identity-deployment'
//   params: {
//     baseName: 'finance'
//     environment: environment
//     location: location
//     tags: tags
//    // keyVaultName: keyVault.outputs.keyVaultName  // Pass Key Vault name from Key Vault module
//   }
// }

//To use this managed identity with other resources:
// Example: Assigning Key Vault access
// resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(keyVault.id, managedIdentity.id, keyVaultSecretsUserRole.id)
//   scope: keyVault
//   properties: {
//     roleDefinitionId: keyVaultSecretsUserRole.id
//     principalId: managedIdentity.properties.principalId
//     principalType: 'ServicePrincipal'
//   }
// }

// // Example: Assigning Storage access
// resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
//   name: guid(storageAccount.id, managedIdentity.id, storageBlobDataContributorRole.id)
//   scope: storageAccount
//   properties: {
//     roleDefinitionId: storageBlobDataContributorRole.id
//     principalId: managedIdentity.properties.principalId
//     principalType: 'ServicePrincipal'
//   }
// }


// // Outputs
// output resourceGroupName string = rg.outputs.resourceGroupName
// output vnetName string = networking.outputs.vnetName
// output defaultSubnetId string = networking.outputs.defaultSubnetId
// output appSubnetId string = networking.outputs.appSubnetId
// output aksSubnetId string = networking.outputs.aksSubnetId
// output vmName string = virtualMachine.outputs.vmName
// output vmPrivateIP string = virtualMachine.outputs.privateIP
// output dataFactoryName string = dataFactory.outputs.dataFactoryName
// output redisHostName string = redis.outputs.redisHostName
// output webAppName string = appService.outputs.webAppName
// output webAppHostName string = appService.outputs.webAppHostName
// output cosmosAccountName string = cosmosDb.outputs.accountName
// output keyVaultName string = keyVault.outputs.keyVaultName
// output logAnalyticsName string = logAnalytics.outputs.logAnalyticsName
// output appInsightsName string = appInsights.outputs.appInsightsName
// output managedIdentityName string = managedIdentity.outputs.managedIdentityName
