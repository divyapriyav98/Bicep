param subnetId string
param location string
// param umiResourceId string // Existing identity
param forceUpdateTag string = utcNow()
param UMIId string
param vnetRG string
param virtualnetwork string
param subnetname string 

resource findAvailableIps 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'findAvailableIps'
  location: location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UMIId}': {}
    }
  }
  properties: {
    azCliVersion: '2.59.0'
    retentionInterval: 'P1D'
    cleanupPreference: 'OnSuccess'
    forceUpdateTag: forceUpdateTag
    timeout: 'PT15M'
    arguments: '--SUBNET_ID "${subnetId }" --VNET_RG "${vnetRG}" --VNET_NAME "${virtualnetwork}" --SUBNET_NAME "${subnetname}"'
    scriptContent: loadTextContent('./Find-FreeIPs.sh')
    outputs: {
      ip1: 'ip1'
      ip2: 'ip2'
      // allocated_ip:'allocated_ip'
    }
  }
  //dependsOn: [ readerRoleAssignment]
}
  
output availableIP1 string = findAvailableIps.properties.outputs.ip1
output availableIP2 string = findAvailableIps.properties.outputs.ip2




