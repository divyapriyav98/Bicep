@description('Required. Name of the Output keyvault.')
param kvName string
@description('Required. Name of the Secret in keyvault to store output.')
param outputSecretName string
@description('Required. Value of the Secret in keyvault to store output as object type.')
@secure()
param outputSecretValue object

resource outputKV 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kvName
  resource secret 'secrets' = {
    name: outputSecretName
    properties: {
      value: string(outputSecretValue)
    }
  }
}

