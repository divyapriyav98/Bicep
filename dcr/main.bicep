@description('The name of the virtual machine scale set.')
param vmssName string
@description('The name of the association.')
param associationName string
param logWorkspaceId  string
param dcrSubscriptionId string
param dcrRgName string

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' existing = {
  name: vmssName

}

// resource amaExtension 'Microsoft.Compute/virtualMachineScaleSets/extensions@2021-07-01' = {
//   name: 'AzureMonitorLinuxAgent'
//   parent: vmss
//   properties: {
//     publisher: 'Microsoft.Azure.Monitor'
//     type: 'AzureMonitorLinuxAgent'
//     typeHandlerVersion: '1.0'
//     autoUpgradeMinorVersion: true
//     // settings: {
//     //   workspaceId: logWorkspaceId
//     // }
//     settings: {
//       authentication: {
//         managedIdentity: {
//           'identifier-name': 'mi_res_id'
//           'identifier-value': userAssignedManagedIdentity
//         }
//       }
//       configuration: {
//         dataCollectionRules: [
//           {
//             id: syslogDcr.id  // Reference to the Syslog DCR
//           }
//           // {
//           //   id: metricsDcr.id  // Reference to Metrics DCR
//           // }
//         ]
//         workspaceId: logWorkspaceId
//       }
//     }
//     protectedSettings: {
//       authentication: {
//         mode: 'AAD'
//       }
//     }
//   }
// }

param syslogDcrName string
// Log Analytics Workspace Resource ID
param location string = ''
 
// resource syslogDcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
//   name: syslogDcrName
//   location: location
//   properties: {
//     description: 'DCR for collecting syslog data.'
//     dataSources: {
//         syslog: [
//           {
//             logLevels: ['Informational', 'Warning', 'Error']
//             facilityNames: ['user']
//           }
//         ]
//       }
    
//     destinations: {
//       logAnalytics: [
//         {
//           workspaceResourceId: logWorkspaceId
//         }
//       ]
//     }
//   }
// }
param userAssignedManagedIdentity string 
// resource windowsAgent 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
//   name: '${vmssName}/AzureMonitorWindowsAgent'
//   location: location
//   properties: {
//     publisher: 'Microsoft.Azure.Monitor'
//     type: 'AzureMonitorWindowsAgent'
//     typeHandlerVersion: '1.0'
//     autoUpgradeMinorVersion: true
//     enableAutomaticUpgrade: true
//     settings: {
//       authentication: {
//         managedIdentity: {
//           'identifier-name': 'mi_res_id'
//           'identifier-value': userAssignedManagedIdentity
//         }
//       }
//       configuration: {
//         dataCollectionRules: [
//           {
//             id: syslogDcr.id
//           }
//         ]
//         workspaceId: logWorkspaceId
//       }
//     }
//   }
//   dependsOn: [
//     vmss
//   ]
// }
// resource syslogDcr 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
//   name: '${vmssName}-syslogdcr' //syslogDcrName
//   location: location
//   properties: {
//     description: 'DCR for collecting syslog data.'
//     dataSources: {
//       syslog: [
//         {
//           name: 'syslogSource'
//           streams: [ 'Microsoft-Syslog' ]
//           facilityNames: [ 'user' ]
//           logLevels: [ 'Info', 'Warning', 'Error' ] // Must use allowed values
//         }
//       ]
//     }
//     destinations: {
//       logAnalytics: [
//         {
//           name: 'logAnalyticsDest'
//           workspaceResourceId: logWorkspaceId
//         }
//       ]
//     }
//     dataFlows: [
//       {
//         streams: [ 'Microsoft-Syslog' ]
//         destinations: [ 'logAnalyticsDest' ]
//       }
//     ]
//   }
//   dependsOn: [
//     vmss
//   ]
// // }

resource syslogDcr 'Microsoft.Insights/dataCollectionRules@2023-01-01' existing = {
  scope: resourceGroup(dcrSubscriptionId, dcrRgName) 
  name: syslogDcrName // Replace with the name of your existing Syslog DCR
  // scope: resourceGroup('1e3fd2bd-6171-4f89-b039-8d2ecee852d3', 'cloudcore-logstorage-work-eastus')
}

resource association 'Microsoft.Insights/dataCollectionRuleAssociations@2023-03-11' = {
  name: associationName
  // scope: vmss
  scope: vmss
  properties: {
    description: 'Association of data collection rule. Deleting this association will break the data collection for this virtual machine.'
    dataCollectionRuleId: syslogDcr.id // Use symbolic reference for the Syslog DCR resource ID
  }
  dependsOn: [syslogDcr]
}

// output datacollectionruleid string = syslogDcr.id
