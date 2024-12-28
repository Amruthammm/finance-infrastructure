param baseName string
param environment string
param location string
param tags object

var managedIdentityName = 'id-${baseName}-${environment}'

//user managed Identity service
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: tags
}

output managedIdentityName string = managedIdentity.name
output managedIdentityId string = managedIdentity.id
output principalId string = managedIdentity.properties.principalId
output clientId string = managedIdentity.properties.clientId
