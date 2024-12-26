// modules/networking.bicep

@description('Base name for the resources')
param baseName string

@description('Environment name')
param environment string

@description('Azure region')
param location string

@description('Resource tags')
param tags object

// Names following your architecture
var vnetName = 'vnet-${baseName}-${environment}'
var nsgName = 'nsg-${baseName}-${environment}'

// Network Security Group
resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: nsgName // Example: nsg-finance-dev
  location: location
  tags: tags
  properties: {
    securityRules: [
       // Rule 1: Allow HTTPS (Port 443)
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 1000 // Lower number = higher priority
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'  
          sourcePortRange: '*' // From any source
          destinationAddressPrefix: '*' 
          destinationPortRange: '443'  // To HTTPS port
        }
      }
      {
         // Rule 2: Allow HTTP (Port 80)
        name: 'AllowHTTP'
        properties: {
          priority: 1100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName // Example: vnet-finance-dev
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'  // Main VNet address space
      ]
    }
    subnets: [
       // Subnet 1: For Web Apps
      {
        name: 'WebAppSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24' // Can host up to 251 resources
          networkSecurityGroup: {
            id: nsg.id // Link to the NSG above
          }
          delegations: [ // Allow Azure Web Apps to use this subnet
            {
              name: 'webAppDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
       // Subnet 2: For Data Services
      {
        name: 'DataSubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

// Outputs
output vnetName string = vnet.name
output vnetId string = vnet.id
output webAppSubnetId string = vnet.properties.subnets[0].id
output dataSubnetId string = vnet.properties.subnets[1].id
