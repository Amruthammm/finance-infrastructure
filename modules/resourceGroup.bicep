// modules/resourceGroup.bicep

// This module must be deployed at subscription scope
targetScope = 'subscription'

@description('Name prefix for the resource group')
param baseName string = 'finance'

@description('Environment (dev, test, or prod)')
@allowed([
  'dev'
  'test'
  'prod'
])
param environment string = 'dev'

@description('Azure region for resource group')
param location string = 'canadacentral'

@description('Tags for the resource group')
param tags object = {
  Environment: environment
  Application: 'Finance'
  ManagedBy: 'Bicep'
}

// Create resource group with the naming convention from your architecture
resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: 'rg-${baseName}-${environment}'    // This will create: rg-finance-dev
  location: location
  tags: tags
}

// Outputs
output resourceGroupName string = resourceGroup.name
output resourceGroupId string = resourceGroup.id
