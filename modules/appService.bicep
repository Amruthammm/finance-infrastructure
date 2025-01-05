// modules/appService.bicep

@description('Base name for the resources')
param baseName string

@description('Environment name')
param environment string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

@description('Resource Group Name')
param resourceGroupName string

@description('Subnet Id')
param subnetId string 

@description('Log Analytics Workspace ID')
param logAnalyticsWorkspaceId string

@description('Application Insights Connection String')
param appInsightsConnectionString string

param storageAccountName string

// Add unique suffix generation
var deploymentId = uniqueString(resourceGroup().id)
var appServicePlanName = 'plan-${baseName}-${environment}-${deploymentId}'
var webAppName = 'app-${baseName}-${environment}-${deploymentId}'

// Create a appservice plan
resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: 'B1'        // Basic tier required for VNet integration
    tier: 'Basic'
    size: 'B1'
    family: 'B'
    capacity: 1
  }
  kind: 'windows'
  properties: {
    reserved: false
    perSiteScaling: false
    maximumElasticWorkerCount: 1
    isSpot: false
    targetWorkerCount: 0
    targetWorkerSizeId: 0
  }
}

resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'STORAGE_ACCOUNT_NAME'
          value: storageAccountName
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'  //for enabling application logs
          value: appInsightsConnectionString
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
      ]
      logs: {
        httpLogs: {
          fileSystem: {
            retentionInMb: 35
            retentionInDays: 7
            enabled: true
          }
        }
        applicationLogs: {
          fileSystem: {
            level: 'Warning'
            retentionInMb: 35
            retentionInDays: 7
            enabled: true
          }
        }
        detailedErrorMessages: {
          enabled: true
        }
        failedRequestsTracing: {
          enabled: true
        }
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Deploy HTML content
resource webAppConfig 'Microsoft.Web/sites/config@2022-09-01' = {
  parent: webApp
  name: 'web'
  properties: {
    defaultDocuments: [
      'index.html'
    ]
  }
}

// resource webApp 'Microsoft.Web/sites@2022-09-01' = {
//   name: webAppName
//   location: location
//   tags: tags
//   properties: {
//     serverFarmId: appServicePlan.id
//     httpsOnly: true
//     virtualNetworkSubnetId: subnetId // VNet integration
//     siteConfig: {
//       vnetRouteAllEnabled: true // Route all traffic through VNet
//       alwaysOn: true            // Supported in Basic tier
//       http20Enabled: true
//       minTlsVersion: '1.2'
//       ftpsState: 'FtpsOnly'
//       use32BitWorkerProcess: true 
//       appSettings: [
//         {
//           name: 'WEBSITE_NODE_DEFAULT_VERSION'
//           value: '~18'
//         }
//         {
//           name: 'WEBSITE_VNET_ROUTE_ALL'   // Required for VNet routing
//           value: '1' 
//         }
//         {
//           name: 'WEBSITE_RESOURCE_GROUP'
//           value: resourceGroupName
//         } 
//         {
//           name: 'APPLICATIONINSIGHTS_CONNECTION_STRING' // This setting in webApp enables Application Insights monitoring
//           value: appInsightsConnectionString
//         }       
//         {
//           name: 'APPLICATIONINSIGHTS_ROLE_NAME'
//           value: webAppName
//         }
//       ]
//     }
//   }
// }

resource webAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'webappDiagnostics-${environment}'
  scope: webApp
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AppServiceHTTPLogs'
        enabled: true
      }
      {
        category: 'AppServiceConsoleLogs'
        enabled: true
      }
      {
        category: 'AppServiceAppLogs'
        enabled: true
      }
      {
        category: 'AppServiceAuditLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

// Outputs
output webAppName string = webApp.name
output webAppHostName string = webApp.properties.defaultHostName
output appServicePlanName string = appServicePlan.name
