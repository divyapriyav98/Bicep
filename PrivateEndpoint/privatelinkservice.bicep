
param privateLinkServiceName string
param location string
param lbFrontendIpId string
param plsSubnetId string
param plsIpConfigName string
param visibilitySubscriptionId string
resource privateLinkService 'Microsoft.Network/privateLinkServices@2023-09-01' = {
  name: privateLinkServiceName
  location: location
  properties: {
    loadBalancerFrontendIpConfigurations: [
      {
        id: lbFrontendIpId
      }
    ]
    visibility: {
      subscriptions: [
        visibilitySubscriptionId
      ]
    }
    autoApproval: {
      subscriptions: []
    }
    enableProxyProtocol: false
    ipConfigurations: [
      {
        name: plsIpConfigName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: plsSubnetId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}



output privateLinkServiceId string = privateLinkService.id


