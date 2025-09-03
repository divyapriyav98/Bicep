param location string
param storageAccountName string
param containerName string
param vnetId string
// param subnetName string
param subnetId string
param privateDnsZoneName string = 'privatelink.blob.core.windows.net' 
param vnetRG string
 
@description('Reference to the existing storage account')
resource existingStorageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: storageAccountName
}
 
@description('Reference to the existing blob container')
resource existingContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' existing = {
  name: '${storageAccountName}/default/${containerName}'
}
 
@description('Reference to the existing Private DNS Zone')
resource existingPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  scope: resourceGroup(vnetRG)
  name: privateDnsZoneName
  
}

@description('Private endpoint for storage blob access')
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: '${storageAccountName}-pe2'
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'blob-vmssconnection'
        properties: {
          privateLinkServiceId: existingStorageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-02-01' = {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob'
        properties: {
          privateDnsZoneId: existingPrivateDnsZone.id
        }
      }
    ]
  }
}
 
output storageAccountFqdn string = '${storageAccountName}.blob.core.windows.net'
