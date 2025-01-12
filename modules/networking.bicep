// modules/networking.bicep

@description('Base name for the resources')
param baseName string

@description('Environment name')
param environment string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

@description('Network configuration')
param networkConfig object

// Name variables
var nsgName = 'nsg-${baseName}-${environment}'
var vnetName = 'vnet-${baseName}-${environment}'
var snetBaseName = 'snet-${baseName}-${environment}'

// Create NSG
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '443'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          priority: 1100
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '80'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowRDP'
        properties: {
          priority: 1200
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        networkConfig.vnetAddressPrefix
      ]
    }
    subnets: [
      // Application Layer Subnet
      {
        name: '${snetBaseName}-application'
        properties: {
          addressPrefix: networkConfig.subnets.applicationSubnet
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          delegations: [
            {
              name: 'Microsoft.Web.serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      // Data Layer Subnet
      {
        name: '${snetBaseName}-data'
        properties: {
          addressPrefix: networkConfig.subnets.dataSubnet
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      // Shared Infrastructure Layer Subnet
      {
        name: '${snetBaseName}-shared'
        properties: {
          addressPrefix: networkConfig.subnets.sharedSubnet
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Outputs
output vnetName string = virtualNetwork.name
output vnetId string = virtualNetwork.id
output applicationSubnetId string = virtualNetwork.properties.subnets[0].id
output dataSubnetId string = virtualNetwork.properties.subnets[1].id
output sharedSubnetId string = virtualNetwork.properties.subnets[2].id
output nsgId string = networkSecurityGroup.id
