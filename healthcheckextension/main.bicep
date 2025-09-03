@description('Deploys Application Health Extension to a VMSS')
param vmssName string
param osType string
param settings object
 
resource healthExtension 'Microsoft.Compute/virtualMachineScaleSets/extensions@2024-11-01' = {
  name: '${vmssName}/HealthExtension'
 
  properties: {
    publisher: 'Microsoft.ManagedServices'
    type: osType == 'Windows' ? 'ApplicationHealthWindows' : 'ApplicationHealthLinux'
    typeHandlerVersion: settings.typeHandlerVersion
    autoUpgradeMinorVersion: settings.autoUpgradeMinorVersion
    settings: {
      protocol: settings.protocol
      port: settings.port
      requestPath: settings.requestPath
      intervalInSeconds: settings.intervalInSeconds
      numberOfProbes: settings.numberOfProbes
      gracePeriod: settings.gracePeriod
    }
  }
}
resource dependencyExtension 'Microsoft.Compute/virtualMachineScaleSets/extensions@2024-11-01' = {
  name: '${vmssName}/DependencyExtension'
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentLinux'
    typeHandlerVersion: '9.5'
    autoUpgradeMinorVersion: true
    settings: {}
  }
  dependsOn: [healthExtension]
}
