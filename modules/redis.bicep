// modules/redis.bicep
param baseName string
param environment string
param location string
param tags object
param subnetId string  // For private endpoint

var redisName = take('redis${baseName}${environment}${uniqueString(resourceGroup().id)}', 24)
var privateEndpointName = 'pe-${redisName}'

// Redis Cache
resource redis 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Basic'    // Basic SKU for dev tier
      family: 'C'
      capacity: 0      // Smallest size (250 MB)
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    redisConfiguration: {
      'maxmemory-policy': 'allkeys-lru'    // Eviction policy
      'maxfragmentationmemory-reserved': '50'
      'maxmemory-reserved': '50'
      'notify-keyspace-events': 'KEA'
    }
    redisVersion: '6.0'
    replicasPerMaster: 1
  }
}

// Private Endpoint for Redis
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
          privateLinkServiceId: redis.id
          groupIds: [
            'redisCache'
          ]
        }
      }
    ]
  }
}

// Patch schedule for Redis
resource patchSchedule 'Microsoft.Cache/redis/patchSchedules@2023-08-01' = {
  parent: redis
  name: 'default'
  properties: {
    scheduleEntries: [
      {
        dayOfWeek: 'Sunday'
        startHourUtc: 2  // 2 AM UTC
        maintenanceWindow: 'PT5H'  // 5 hour window
      }
    ]
  }
}

// Diagnostic settings for Redis
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${redisName}-diagnostics'
  scope: redis
  properties: {
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'ConnectedClientList'
        enabled: true
      }
    ]
  }
}

// Firewall rules (if needed for specific IPs)
resource firewallRules 'Microsoft.Cache/redis/firewallRules@2023-08-01' = {
  parent: redis
  name: 'AllowVnet'
  properties: {
    startIP: '0.0.0.0'
    endIP: '0.0.0.0'  // This effectively allows only VNet access
  }
}

// Outputs
output redisName string = redis.name
output redisHostName string = '${redis.name}.redis.cache.windows.net'
output redisPrincipalId string = redis.identity.principalId
output privateEndpointId string = privateEndpoint.id
@description('The primary access key. Use listKeys() instead of direct reference')
output redisPrimaryKey string = redis.listKeys().primaryKey
