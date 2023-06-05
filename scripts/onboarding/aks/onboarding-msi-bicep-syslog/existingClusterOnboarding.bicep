@description('AKS Cluster Resource ID')
param aksResourceId string

@description('Location of the AKS resource e.g. "East US"')
param aksResourceLocation string

@description('Existing or new tags to use on AKS, ContainerInsights and DataCollectionRule Resources')
param resourceTagValues object

@description('Workspace Region for data collection rule')
param workspaceRegion string

@description('Full Resource ID of the log analitycs workspace that will be used for data destination. For example /subscriptions/00000000-0000-0000-0000-0000-00000000/resourceGroups/ResourceGroupName/providers/Microsoft.operationalinsights/workspaces/ws_xyz')
param workspaceResourceId string

@description('Array of allowed syslog levels')
param syslogLevels array

@description('Array of allowed syslog facilities')
param syslogFacilities array

var clusterSubscriptionId = split(aksResourceId, '/')[2]
var clusterResourceGroup = split(aksResourceId, '/')[4]
var clusterName = split(aksResourceId, '/')[8]
var workspaceLocation = replace(workspaceRegion, ' ', '')
var dcrNameFull = 'MSCI-${workspaceLocation}-${clusterName}'
var dcrName = ((length(dcrNameFull) > 64) ? substring(dcrNameFull, 0, 64) : dcrNameFull)
var associationName = 'ContainerInsightsExtension'
var dataCollectionRuleId = resourceId(clusterSubscriptionId, clusterResourceGroup, 'Microsoft.Insights/dataCollectionRules', dcrName)

resource aks_monitoring_msi_dcr 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: dcrName
  location: workspaceRegion
  tags: resourceTagValues
  kind: 'Linux'
  properties: {
    dataSources: {
      syslog: [
        {
          streams: [
            'Microsoft-Syslog'
          ]
          facilityNames: syslogFacilities
          logLevels: syslogLevels
          name: 'sysLogsDataSource'
        }
      ]
      extensions: [
        {
          name: 'ContainerInsightsExtension'
          streams: [
            'Microsoft-ContainerInsights-Group-Default'
          ]
          extensionName: 'ContainerInsights'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: workspaceResourceId
          name: 'ciworkspace'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-ContainerInsights-Group-Default'
          'Microsoft-Syslog'
        ]
        destinations: [
          'ciworkspace'
        ]
      }
    ]
  }
}

resource aks_monitoring_msi_addon 'Microsoft.ContainerService/managedClusters@2018-03-31' = {
  name: clusterName
  location: aksResourceLocation
  tags: resourceTagValues
  properties: {
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: workspaceResourceId
          useAADAuth: 'true'
        }
      }
    }
  }
}

resource aks_monitoring_msi_dcra 'microsoft.insights/dataCollectionRuleAssociations@2022-06-01' = {
  name: associationName
  scope: aks_monitoring_msi_addon
  properties: {
    description: 'Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster.'
    dataCollectionRuleId: dataCollectionRuleId
  }
  dependsOn: [
    aks_monitoring_msi_dcr
  ]
}
