// modules/networking.bicep

@description('Base name for the resources')
param baseName string
@description('Environment name')
param environment string
@description('Azure region')
param location string
@description('Resource tags')
param tags object

// Name variables
var nsgName = 'nsg-${baseName}-${environment}'
var vnetName = 'vnet-${baseName}-${environment}'
var snetName = 'snet-${baseName}-${environment}'  // Generic subnet naming

// Address space variables
var vnetAddressPrefix = '10.0.0.0/16'
var defaultSubnetPrefix = '10.0.0.0/24'
var appSubnetPrefix = '10.0.1.0/24'
var dataSubnetPrefix = '10.0.2.0/24'    // For data services (Cosmos, Redis, etc.)


// Create NSG
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-05-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      // HTTP and HTTPS rules
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
        vnetAddressPrefix // '10.0.0.0/16'
      ]
    }
    subnets: [
      // Default subnet
      {
        name: '${snetName}-default'      // Generic default subnet
        properties: {
          addressPrefix: defaultSubnetPrefix // '10.0.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id  // Link NSG
          }
        }
      }
      {
        name: '${snetName}-app'          // For App Services
        properties: {
          addressPrefix: appSubnetPrefix  // '10.0.1.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: '${snetName}-data'         // For all data services
        properties: {
          addressPrefix: dataSubnetPrefix  //'10.0.2.0/24'
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
output defaultSubnetId string = virtualNetwork.properties.subnets[0].id
output appSubnetId string = virtualNetwork.properties.subnets[1].id
output dataSubnetId string = virtualNetwork.properties.subnets[2].id
output nsgId string = networkSecurityGroup.id
