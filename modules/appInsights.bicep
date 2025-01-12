// modules/appInsights.bicep
param baseName string
param environment string
param location string
param tags object
param logAnalyticsWorkspaceId string
param subnetId string

var appInsightsName = 'ai-${baseName}-${environment}'
var privateEndpointName = 'pe-${appInsightsName}'

// Application Insights resource
resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspaceId
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'  // Keep enabled for initial setup
    publicNetworkAccessForQuery: 'Enabled'      // Keep enabled for initial setup
    DisableIpMasking: false
    SamplingPercentage: 100
    RetentionInDays: 90
    Flow_Type: 'Bluefield'
  }
}

// Private Endpoint for Application Insights
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
          privateLinkServiceId: appInsights.id
          groupIds: [
            'appinsights'
          ]
        }
      }
    ]
  }
}

// Configure action group for alerts
resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${appInsightsName}'
  location: 'global'
  properties: {
    groupShortName: 'AppInsights'
    enabled: true
    emailReceivers: [
      {
        name: 'emailAction'
        emailAddress: 'admin@contoso.com'
        useCommonAlertSchema: true
      }
    ]
  }
}

// Smart Detection Rule
resource smartDetection 'Microsoft.Insights/components/ProactiveDetectionConfigs@2018-05-01-preview' = {
  name: '${appInsights.name}/failure anomalies'
  properties: {
    Name: 'Failure Anomalies'
    Enabled: true
    SendEmailsToSubscriptionOwners: true
    CustomEmails: []
  }
}

// Outputs
output appInsightsName string = appInsights.name
output appInsightsId string = appInsights.id
output instrumentationKey string = appInsights.properties.InstrumentationKey
output connectionString string = appInsights.properties.ConnectionString
output privateEndpointId string = privateEndpoint.id
