// modules/containerApp.bicep
param baseName string
param environment string
param location string
param tags object
param subnetId string

var containerAppName = 'aca-${baseName}-${environment}'
var containerEnvName = 'env-${baseName}-${environment}'
var logWorkspaceName = 'log-${baseName}-${environment}'

// Log Analytics workspace for Container Apps
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: 1
    }
  }
}

// Container Apps Environment
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerEnvName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logWorkspace.properties.customerId
        sharedKey: logWorkspace.listKeys().primarySharedKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: subnetId
      internal: false  // Set to true if you want internal-only access
    }
    zoneRedundant: false
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'  // Enable system-assigned managed identity
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: false
        transport: 'auto'
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
      secrets: []
      registries: []
      dapr: {
        enabled: false
      }
      service: {
        type: 'loadBalancer'
      }
    }
    template: {
      containers: [
        {
          name: 'myapp'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')    // 0.5 CPU cores
            memory: '1Gi'       // 1GB memory
          }
          env: []
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/'
                port: 80
                scheme: 'HTTP'
              }
              periodSeconds: 10
              timeoutSeconds: 1
              failureThreshold: 3
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/'
                port: 80
                scheme: 'HTTP'
              }
              periodSeconds: 10
              timeoutSeconds: 1
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 1
        rules: [
          {
            name: 'http-rule'
            http: {
              metadata: {
                concurrentRequests: '100'
              }
            }
          }
        ]
      }
    }
  }
}

//without subnet and for free trail
// // Container Apps Environment
// resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
//   name: containerEnvName
//   location: location
//   tags: tags
//   properties: {
//     appLogsConfiguration: {
//       destination: 'log-analytics'
//       logAnalyticsConfiguration: {
//         customerId: logWorkspace.properties.customerId
//         sharedKey: logWorkspace.listKeys().primarySharedKey
//       }
//     }
//     vnetConfiguration: {
//       infrastructureSubnetId: subnetId
//     }
//   }
// }

// // Container App
// resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
//   name: containerAppName
//   location: location
//   tags: tags
//   properties: {
//     managedEnvironmentId: containerAppEnv.id
//     configuration: {
//       ingress: {
//         external: true
//         targetPort: 80
//       }
//     }
//     template: {
//       containers: [
//         {
//           name: 'myapp'
//           image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
//           resources: {
//             cpu: json('0.5')    // 0.5 CPU cores
//             memory: '1Gi'       // 1GB memory
//           }
//         }
//       ]
//       scale: {
//         minReplicas: 0
//         maxReplicas: 1
//       }
//     }
//   }
// }

// Diagnostic settings for Container App
resource containerAppDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${containerAppName}-diagnostics'
  scope: containerApp
  properties: {
    workspaceId: logWorkspace.id
    logs: [
      {
        category: 'ContainerAppConsoleLogs'
        enabled: true
      }
      {
        category: 'ContainerAppSystemLogs'
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

// Outputs
output containerAppUrl string = containerApp.properties.configuration.ingress.fqdn
output containerAppPrincipalId string = containerApp.identity.principalId
output containerAppName string = containerApp.name
output logWorkspaceId string = logWorkspace.id
output environmentName string = containerAppEnv.name


