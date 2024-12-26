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

// @description('Subnet ID for VNet integration')
// param subnetId string

// Add unique suffix generation
var deploymentId = uniqueString(resourceGroup().id)
var appServicePlanName = 'ASP-testsynapseworkspacgroup-${deploymentId}' 
var webAppName = 'app-${baseName}-${environment}-${deploymentId}'


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

// Web App
resource webApp 'Microsoft.Web/sites@2022-09-01' = {
  name: webAppName
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    virtualNetworkSubnetId: subnetId  // VNet integration
    siteConfig: {
      vnetRouteAllEnabled: true      // Route all traffic through VNet
      alwaysOn: true                 // Supported in Basic tier
      http20Enabled: true
      minTlsVersion: '1.2'
      ftpsState: 'FtpsOnly'
      use32BitWorkerProcess: true 
      appSettings: [
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~18'
        }
        {
          name: 'WEBSITE_VNET_ROUTE_ALL' // Required for VNet routing
          value: '1'
        }
      ]
    }
  }
}
// Outputs
output webAppName string = webApp.name
output webAppHostName string = webApp.properties.defaultHostName
output appServicePlanName string = appServicePlan.name
