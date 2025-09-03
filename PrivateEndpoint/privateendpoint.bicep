// targetScope = 'resourceGroup'

param privateEndpointName string
param location string
param privateEndpointNicName string
param privateLinkConnectionName string
param privateLinkServiceId string
param groupIds array
param tierName string
// param pesubnetid string
// commenting below as work and nonp uses same vnetname
// peVnetName  = 'vnet-eastus-${tierName}-mcrouteable-private-endpoint'

var peVnetName  = tierName == 'prod'?'vnet-eastus-prod-mcrouteable-private-endpoint': tierName == 'nonp'?'vnet-eastus-nonp-mcrouteable-private-endpoint': tierName == 'work'?'vnet-eastus-nonp-mcrouteable-private-endpoint': 'skip'
var peSubscriptionId = tierName == 'prod'? 'c867858e-2261-4347-b241-fa3d17b40fba': 'ffaa29d0-3efc-4804-847c-6d48627c2b70'
var peResourceGroupName = tierName == 'prod'? 'rg-cloudcore-mcrouteable-private-endpoint-eastus-prod': 'rg-cloudcore-mcrouteable-private-endpoint-eastus-nonp'
var privateEndpointSubnetId = '/subscriptions/${peSubscriptionId}/resourceGroups/${peResourceGroupName}/providers/Microsoft.Network/virtualNetworks/${peVnetName}/subnets/PrivateEndpoints'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId // Construct dynamically
    }
    customNetworkInterfaceName: privateEndpointNicName
    privateLinkServiceConnections: [
      {
        name: privateLinkConnectionName
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
  }
}
