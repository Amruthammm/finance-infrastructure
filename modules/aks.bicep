// modules/aks.bicep
param baseName string
param environment string
param location string
param tags object
param subnetId string

var clusterName = 'aks-${baseName}-${environment}'
var nodePoolName = 'nodepool1'
var networkPlugin = 'azure'  // Changed to azure CNI for better network integration
var logAnalyticsWorkspaceName = 'log-${baseName}-${environment}'

// Create Log Analytics workspace for container insights
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' = {
  name: clusterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Basic'
    tier: 'Free'  // Using Free tier as specified
  }
  properties: {
    dnsPrefix: clusterName
    enableRBAC: true
    agentPoolProfiles: [
      {
        name: nodePoolName
        count: 1              // Minimum nodes for free tier
        vmSize: 'Standard_B2s' // Smallest available VM size
        mode: 'System'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        vnetSubnetID: subnetId
        enableAutoScaling: false
        maxPods: 30          // Reduced max pods for basic tier
        availabilityZones: [] // No availability zones in free tier
        enableNodePublicIP: false
        type: 'VirtualMachineScaleSets'
        upgradeSettings: {
          maxSurge: '33%'
        }
      }
    ]
    networkProfile: {
      networkPlugin: networkPlugin
      networkPolicy: 'azure'     // Using Azure network policy
      serviceCidr: '172.16.0.0/16'  // Changed to avoid overlap with VNet
      dnsServiceIP: '172.16.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
      loadBalancerSku: 'standard'
    }
    aadProfile: {
      enableAzureRBAC: true
      managed: true
    }
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
      }
      azurepolicy: {
        enabled: true
      }
    }
    securityProfile: {
      defender: {
        logAnalyticsWorkspaceResourceId: logAnalyticsWorkspace.id
        securityMonitoring: {
          enabled: true
        }
      }
    }
  }
}

// Deploy monitoring diagnostics settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'AKSDiagnostics'
  scope: aksCluster
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'kube-apiserver'
        enabled: true
      }
      {
        category: 'kube-audit'
        enabled: true
      }
      {
        category: 'kube-audit-admin'
        enabled: true
      }
      {
        category: 'kube-controller-manager'
        enabled: true
      }
      {
        category: 'kube-scheduler'
        enabled: true
      }
      {
        category: 'cluster-autoscaler'
        enabled: true
      }
      {
        category: 'guard'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output clusterName string = aksCluster.name
output controlPlaneFQDN string = aksCluster.properties.fqdn
output clusterIdentityPrincipalId string = aksCluster.identity.principalId
output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output kubeletIdentityObjectId string = aksCluster.properties.identityProfile.kubeletidentity.objectId



// resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' = {
//   name: clusterName
//   location: location
//   tags: tags
//   identity: {
//     type: 'SystemAssigned'
//   }
//   properties: {
//     dnsPrefix: clusterName
//     agentPoolProfiles: [
//       {
//         name: nodePoolName
//         count: 1              // Minimum nodes for free tier
//         vmSize: 'Standard_B2s' // Smallest available VM size
//         mode: 'System'
//         osType: 'Linux'
//         osSKU: 'Ubuntu'
//         vnetSubnetID: subnetId
//         enableAutoScaling: false
//         maxPods: 30          // Reduce max pods
//         availabilityZones: [] // No availability zones for free tier
//       }
//     ]
//     networkProfile: {
//       networkPlugin: 'kubenet'  // Changed to kubenet from azure for less resource usage
//       serviceCidr: '172.16.0.0/16'
//       dnsServiceIP: '172.16.0.10'
//       podCidr: '172.17.0.1/16'
//     }
//   }
// }
