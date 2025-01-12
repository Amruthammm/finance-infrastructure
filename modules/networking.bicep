// modules/networking.bicep
param baseName string
param environment string
param location string
param tags object
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
      // Web Apps Subnet
      {
        name: '${snetBaseName}-webapp'
        properties: {
          addressPrefix: networkConfig.applicationLayer.subnets.webApp
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
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      // Container Apps Subnet
      {
        name: '${snetBaseName}-containerapp'
        properties: {
          addressPrefix: networkConfig.applicationLayer.subnets.containerApp
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          delegations: [
            {
              name: 'Microsoft.App.environments'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      // Function Apps Subnet
      {
        name: '${snetBaseName}-function'
        properties: {
          addressPrefix: networkConfig.applicationLayer.subnets.functionApp
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
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      // VM Subnet
      {
        name: '${snetBaseName}-vm'
        properties: {
          addressPrefix: networkConfig.applicationLayer.subnets.vm
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      // AKS Subnet
      {
        name: '${snetBaseName}-aks'
        properties: {
          addressPrefix: networkConfig.applicationLayer.subnets.aks
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      // Data Layer Subnet
      {
        name: '${snetBaseName}-data'
        properties: {
          addressPrefix: networkConfig.dataLayer.prefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: []
        }
      }
      // Shared Layer Subnet
      {
        name: '${snetBaseName}-shared'
        properties: {
          addressPrefix: networkConfig.sharedLayer.prefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          delegations: []
        }
      }
    ]
  }
}

// Outputs
output vnetName string = virtualNetwork.name
output vnetId string = virtualNetwork.id
output webAppSubnetId string = virtualNetwork.properties.subnets[0].id
output containerAppSubnetId string = virtualNetwork.properties.subnets[1].id
output functionSubnetId string = virtualNetwork.properties.subnets[2].id
output vmSubnetId string = virtualNetwork.properties.subnets[3].id
output aksSubnetId string = virtualNetwork.properties.subnets[4].id
output dataSubnetId string = virtualNetwork.properties.subnets[5].id
output sharedSubnetId string = virtualNetwork.properties.subnets[6].id
output nsgId string = networkSecurityGroup.id
