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
      name: 'PerGB2018'  // Pay-as-you-go tier
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      immediatePurgeDataOn30Days: true
    }
    workspaceCapping: {
      dailyQuotaGb: 1  // Set daily data cap
    }
    publicNetworkAccessForIngestion: 'Enabled'  // Keep enabled for initial setup
    publicNetworkAccessForQuery: 'Enabled'      // Keep enabled for initial setup
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

// Solutions
resource containerInsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ContainerInsights(${logAnalytics.name})'
  location: location
  tags: tags
  properties: {
    workspaceResourceId: logAnalytics.id
  }
  plan: {
    name: 'ContainerInsights(${logAnalytics.name})'
    product: 'OMSGallery/ContainerInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
}

resource vmInsights 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'VMInsights(${logAnalytics.name})'
  location: location
  tags: tags
  properties: {
    workspaceResourceId: logAnalytics.id
  }
  plan: {
    name: 'VMInsights(${logAnalytics.name})'
    product: 'OMSGallery/VMInsights'
    publisher: 'Microsoft'
    promotionCode: ''
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

// Data Collection Rules
resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2021-09-01-preview' = {
  name: 'dcr-${logAnalyticsName}'
  location: location
  tags: tags
  properties: {
    dataCollectionEndpointId: null
    description: 'Data collection rule for VM insights'
    dataSources: {
      performanceCounters: [
        {
          name: 'VMInsightsPerfCounters'
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\Processor Information(_Total)\\% Processor Time'
            '\\Memory\\Available Bytes'
            '\\LogicalDisk(_Total)\\Free Megabytes'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'VMInsightsPerf'
          workspaceResourceId: logAnalytics.id
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'VMInsightsPerf'
        ]
      }
    ]
  }
}

// Outputs
output logAnalyticsId string = logAnalytics.id
output logAnalyticsName string = logAnalytics.name
output workspaceKey string = logAnalytics.listKeys().primarySharedKey
output privateEndpointId string = privateEndpoint.id
