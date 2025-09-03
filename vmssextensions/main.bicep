param vmssName string
param extensionsname string
param userAssignedManagedIdentity string
param adminUsername string 
param sshPublicKey string
resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2024-11-01' existing = {
  name: vmssName
}

resource vmssExtension 'Microsoft.Compute/virtualMachineScaleSets/extensions@2024-11-01' = {
  name: extensionsname//'VMAccessExtension'
  parent: vmss
  properties: {
    publisher: 'Microsoft.OSTCExtensions'
    type: 'VMAccessForLinux'
    typeHandlerVersion: '1.5'
    autoUpgradeMinorVersion: true
    settings: {}
    // protectedSettings: {}
    protectedSettings: {
      username: adminUsername  // Or your actual username
      ssh_key: sshPublicKey  // Must be the full SSH public key string
    }
  }
  
  dependsOn: [vmss]
}



resource linuxAgent 'Microsoft.Compute/virtualMachineScaleSets/extensions@2024-11-01' = {
  name: 'AzureMonitorLinuxAgent'
  parent: vmss
  // location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorLinuxAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      authentication: {
        managedIdentity: {
          'identifier-name': 'mi_res_id'
          'identifier-value': userAssignedManagedIdentity
        }
      }
    }
  }
  dependsOn: [vmss
  vmssExtension]
}







