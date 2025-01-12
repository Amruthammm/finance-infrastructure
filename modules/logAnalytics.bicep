// modules/logAnalytics.bicep
param baseName string
param environment string
param location string
param tags object
param subnetId string

var logAnalyticsName = 'log-${baseName}-${environment}'
var privateEndpointName = 'pe-${logAnalyticsName}'

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'  // Change to a supported SKU tier
    }
    retentionInDays: 30  // Adjust the retention period as needed
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}


// Private Endpoint for Log Analytics
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: logAnalytics.id
          groupIds: [
            'azuremonitor'
          ]
        }
      }
    ]
  }
}

// Saved Searches
resource savedSearches 'Microsoft.OperationalInsights/workspaces/savedSearches@2020-08-01' = {
  parent: logAnalytics
  name: 'AllResources'
  properties: {
    category: 'General'
    displayName: 'All Resources'
    query: 'search *'
    version: 2
  }
}

// Outputs
output logAnalyticsId string = logAnalytics.id
output logAnalyticsName string = logAnalytics.name
output workspaceKey string = logAnalytics.listKeys().primarySharedKey
output privateEndpointId string = privateEndpoint.id




