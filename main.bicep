// main.bicep
targetScope = 'resourceGroup'

param environment string 

@description('Location for all resources')
param location string

param resourceGroupName string

param tags object 

param baseName string

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
  }
}

// // Deploy App Service with VNet integration
module appService 'modules/appService.bicep' = {
  name: 'appService-deployment'
  params: {
    baseName: baseName //Pass parameters to module
    environment: environment
    location: location
    tags: tags
    resourceGroupName: resourceGroupName
    storageAccountName: storage.outputs.storageAccountName
    subnetId: networking.outputs.appSubnetId  // Connect to the app subnet    
    logAnalyticsWorkspaceId: logAnalytics.outputs.logAnalyticsId
    appInsightsConnectionString: appInsights.outputs.connectionString

  }
}

// module functionApp 'modules/functionApp.bicep' = {  
//   name: 'functionapp-deployment'
//   params: {
//     baseName: 'finance'
//     environment: environment
//     location: location
//     tags: tags
//     resourceGroupName: resourceGroupName
//    // subnetId: networking.outputs.appSubnetId //Pass parameters to module if used premium plan 
//   }
// }

// module aks 'modules/aks.bicep' = {  
//   name: 'aks-deployment'
//   params: {
//     baseName: 'finance'
//     environment: environment
//     location: location
//     tags: tags
//     subnetId: networking.outputs.aksSubnetId
//   }
//   dependsOn: [
//           rg
//        ]
// }
// module containerApp 'modules/containerApp.bicep' = {
//   name: 'containerapp-deployment'
//   params: {
//     baseName: 'finance'
//     environment: environment
//     location: location
//     tags: tags
//     subnetId: networking.outputs.containerAppSubnetId  
//     resourceGroupName: resourceGroupName
//   }
// }
//  module cosmosDb 'modules/cosmosDb.bicep' = {  
//    name: 'cosmos-deployment'
//    params: {
//      baseName: 'finance'
//      environment: environment
//      location: location
//      tags: tags
//      subnetId: networking.outputs.dataSubnetId
//    }
//    dependsOn: [
//      rg
//    ]
//  }

//  module keyVault 'modules/keyvault.bicep' = {   
//    name: 'keyvault-deployment'
//    params: {
//      baseName: 'finance'
//      environment: environment
//      location: location
//      tags: tags
//      subnetId: networking.outputs.dataSubnetId
//    }
//  }

// module redis 'modules/redis.bicep' = {  
//   name: 'redis-deployment'
//   params: {
//     baseName: 'finance'
//     environment: environment
//     location: location
//     tags: tags
//     subnetId: networking.outputs.dataSubnetId
//   }
// }

// // // VM Module
// module virtualMachine 'modules/vm.bicep' = {  
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

//  module dataFactory 'modules/dataFactory.bicep' = {   
//    name: 'adf-deployment'
//    params: {
//      baseName: 'finance'
//      environment: environment
//      location: location
//      tags: tags
//      subnetId: networking.outputs.dataSubnetId
//      //keyVaultId: keyVault.outputs.keyVaultId    
//      //cosmosDbId: cosmosDb.outputs.accountName
//    }
//  }



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
