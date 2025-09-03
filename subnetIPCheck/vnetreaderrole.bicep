param principalId string
param vnetResourceId string

resource vnetRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(principalId, 'vnet-reader-role') 
  properties: {
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'acdd72a7-3385-48ef-bd42-f606fba81ae7' // Reader
    )
  }
}
