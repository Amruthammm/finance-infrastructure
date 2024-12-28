// modules/aks.bicep
param baseName string
param environment string
param location string
param tags object
param subnetId string

var clusterName = 'aks-${baseName}-${environment}'
var nodePoolName = 'nodepool1'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-07-02-preview' = {
  name: clusterName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterName
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
        maxPods: 30          // Reduce max pods
        availabilityZones: [] // No availability zones for free tier
      }
    ]
    networkProfile: {
      networkPlugin: 'kubenet'  // Changed to kubenet from azure for less resource usage
      serviceCidr: '10.0.0.0/16'
      dnsServiceIP: '10.0.0.10'
      podCidr: '10.244.0.0/16'
    }
  }
}

output clusterName string = aksCluster.name
output controlPlaneFQDN string = aksCluster.properties.fqdn
