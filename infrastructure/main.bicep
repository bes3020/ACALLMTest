@description('Name of the Container App')
param containerAppName string = 'huggingface-llm'

@description('Location for all resources')
param location string = resourceGroup().location

@description('Container App Environment name')
param environmentName string = 'llm-environment'

@description('Hugging Face Model ID to deploy (e.g., google/flan-t5-small, microsoft/phi-2)')
param modelId string = 'google/flan-t5-small'

@description('Hugging Face API token (required for private models or to avoid rate limits)')
@secure()
param huggingFaceToken string = ''

@description('Log Analytics Workspace name')
param logAnalyticsName string = 'llm-logs'

@description('Container CPU cores (0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2)')
param cpuCore string = '2.0'

@description('Container memory in GB (0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4)')
param memorySize string = '4Gi'

@description('Minimum number of replicas')
param minReplicas int = 1

@description('Maximum number of replicas')
param maxReplicas int = 3

@description('TGI Container Image Version')
param tgiImageVersion string = 'latest'

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Container App Environment
resource environment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: environmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Container App
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        transport: 'http'
        allowInsecure: false
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
      secrets: [
        {
          name: 'huggingface-token'
          value: huggingFaceToken
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'tgi'
          image: 'ghcr.io/huggingface/text-generation-inference:${tgiImageVersion}'
          resources: {
            cpu: json(cpuCore)
            memory: memorySize
          }
          env: [
            {
              name: 'MODEL_ID'
              value: modelId
            }
            {
              name: 'HUGGING_FACE_HUB_TOKEN'
              secretRef: 'huggingface-token'
            }
            {
              name: 'PORT'
              value: '80'
            }
            {
              name: 'MAX_CONCURRENT_REQUESTS'
              value: '128'
            }
            {
              name: 'MAX_INPUT_LENGTH'
              value: '1024'
            }
            {
              name: 'MAX_TOTAL_TOKENS'
              value: '2048'
            }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: 80
              }
              initialDelaySeconds: 60
              periodSeconds: 30
              failureThreshold: 3
            }
            {
              type: 'Readiness'
              httpGet: {
                path: '/health'
                port: 80
              }
              initialDelaySeconds: 60
              periodSeconds: 10
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

output containerAppFQDN string = containerApp.properties.configuration.ingress.fqdn
output containerAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
