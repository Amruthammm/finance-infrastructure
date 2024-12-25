// modules/appService.bicep
@description('Base name for the app service')
param baseName string

@description('Location for the App Service')
param location string = resourceGroup().location

@description('Environment (dev, test, or prod)')
param environment string

@description('App Service Plan SKU')
param skuName string = 'F1'

@description('Tags for resources')
param tags object = {
  Environment: environment
  Application: 'Finance'
}

var appServicePlanName = 'plan-${baseName}-${environment}'
var webAppName = 'app-${baseName}-${environment}'

resource appServicePlan 'Microsoft.Web/serverfarms@2021-02-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOTNETCORE|6.0'
      alwaysOn: true
    }
  }
}

output webAppName string = webApp.name
output webAppHostName string = webApp.properties.defaultHostName
