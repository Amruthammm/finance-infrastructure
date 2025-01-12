// modules/keyvault.bicep
param baseName string
param environment string
param location string
param tags object
param subnetId string

var uniqueSuffix = uniqueString(subscription().id, resourceGroup().id, deployment().name)
var kvName = 'kv${baseName}${environment}${take(uniqueSuffix, 5)}'
var privateEndpointName = 'pe-${kvName}'

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: kvName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enabledForDeployment: true          // VMs can retrieve certificates
    enabledForDiskEncryption: true      // For use with disk encryption
    enabledForTemplateDeployment: true  // ARM templates can retrieve values
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: [
        {
          id: subnetId
          ignoreMissingVNetServiceEndpoint: false
        }
      ]
    }
    publicNetworkAccess: 'Disabled'     // Disable public access
    createMode: 'default'
  }
}

// Private Endpoint configuration
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
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

// Diagnostic settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${kvName}-diagnostics'
  scope: keyVault
  properties: {
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
      {
        category: 'AzurePolicyEvaluationDetails'
        enabled: true
      }
    ]
  }
}

// Add some sample roles
resource adminRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '00482a5a-887f-4fb3-b363-3b7fe8e74483' // Key Vault Administrator
}

resource secretRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
}

// Sample secrets policy
resource secretsPolicy 'Microsoft.KeyVault/vaults/secrets@2023-02-01' = {
  parent: keyVault
  name: 'SecretRotationPolicy'
  properties: {
    attributes: {
      enabled: true
      exp: 1735689600  // Set expiration time
      nbf: 1609459200  // Set not-before time
    }
    contentType: 'application/json'
    value: json('{"rotationInterval": "P90D"}')  // 90-day rotation policy
  }
}

// Outputs
output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output keyVaultUri string = keyVault.properties.vaultUri
output privateEndpointId string = privateEndpoint.id
