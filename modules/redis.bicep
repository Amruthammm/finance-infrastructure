// modules/redis.bicep
param baseName string
param environment string
param location string
param tags object
param subnetId string  // For private endpoint

var redisName = take('redis${baseName}${environment}${uniqueString(resourceGroup().id)}', 24)
var privateEndpointName = 'redispe-${redisName}'

// Redis Cache
resource redis 'Microsoft.Cache/redis@2023-08-01' = {
  name: redisName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'Basic'    // Basic SKU for free/dev tier
      family: 'C'
      capacity: 0      // Smallest size (250 MB)
    }
    enableNonSslPort: false
    minimumTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
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

output redisName string = redis.name
output redisHostName string = '${redis.name}.redis.cache.windows.net'
output redisPrimaryKey string = redis.listKeys().primaryKey
