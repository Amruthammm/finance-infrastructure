// modules/keyvault.bicep
param baseName string
param environment string
param location string
param tags object
param subnetId string

var uniqueSuffix = uniqueString(subscription().id, resourceGroup().id)
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
   accessPolicies: []
   enableRbacAuthorization: true
   enabledForDeployment: true
   enabledForDiskEncryption: true
   enabledForTemplateDeployment: true
   publicNetworkAccess: 'Enabled'
 }
}

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

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
