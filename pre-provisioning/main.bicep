metadata name = 'Pre=Provisioned Resources'
metadata description = 'This module generates a Key to be applied to resources for Azure Key Vault.'

@description('Required. Name of the CMK keyvault.')
param kvName string
@description('Required. Tenant ID.')
param tenantId string
@description('Required. Princpal ID to grant access to CMK.')
param umiPrincipalId string


// ======================= //
//   CMK and Access Policy //
// ======================= //

resource cmkKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kvName
 }

resource key 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: cmkKeyVault
  name: 'vmss-rsa-ec-v2'  // https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-data-encryption#requirements-for-configuring-data-encryption-for-azure-database-for-postgresql-flexible-server
  properties: {
    kty: 'RSA'
    keyOps: [
      'verify'
      'encrypt'
      'decrypt'
      'unwrapKey'
      'wrapKey'
    ]
    keySize: 4096
    curveName: 'P-256'
    rotationPolicy: {
      attributes: {
        expiryTime: 'P2Y'
      }
      lifetimeActions: [
        {
          trigger: {
            timeBeforeExpiry: 'P2M'
          }
          action: {
            type: 'rotate'
          }
        }
        {
          trigger: {
            timeBeforeExpiry: 'P30D'
          }
          action: {
            type: 'notify'
          }
        }
      ]
    }
  }
}

resource accessPolicies 'Microsoft.KeyVault/vaults/accessPolicies@2023-07-01' = {
  parent: cmkKeyVault
  name: 'add'
  properties: {
    accessPolicies : [
      { 
        objectId: umiPrincipalId
        permissions: {
          keys: [
            'get'
            'unwrapKey'
            'wrapKey'
          ]
        }
      tenantId: tenantId
    }
    ]
  }
}


@description('CMK Name')
output cmkName string = key.name



