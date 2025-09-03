param location string //= 'eastus'
param dnsZoneName string //= 'eastus.az.mastercard.local'
// param resourceGroupName string
param ttl int = 10
 
@description('Each record contains a name and a list of IPs')
param aRecords array
// param vnetId string
//param aRecords array = [
//   {
//     name: 'authnz360.dev.eastus.7246827ts28100401'
//     ips: [
//       '10.0.26.11'
//       '10.0.26.12'
//     ]
//   }
//   {
//     name: 'dev.authnz360'
//     ips: [
//       '10.0.26.13'
//     ]
//   }
// ] 
 resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: dnsZoneName
  location: 'global'
}

 
resource recordSetA 'Microsoft.Network/privateDnsZones/A@2024-06-01' = [for record in aRecords: {
  parent: privateDnsZone
  name: record.name
  properties: {
    ttl: ttl
    aRecords: [for ip in record.ips: {
      ipv4Address: ip
    }]
    // isAutoRegistered: false
    // Removed isAutoRegistered as it is read-only
  }
}]

param cn_name string = ''//'hacl'
param cnameTarget string 
 
var cnameNames = [
  cn_name           // This is 'hacl'
  '${cn_name}.standby'  // This becomes 'stg.hacl'
]

var cnameTargets = [for record in aRecords: '${record.name}']

resource cnameRecords 'Microsoft.Network/privateDnsZones/CNAME@2024-06-01' = [
  for i in range(0, length(cnameNames)): {
    name: cnameNames[i]  // 'hacl' and 'stg.hacl'
    parent: privateDnsZone
    properties: {
      ttl: ttl
      cnameRecord: {
        cname: cnameTargets[i]  // Uses corresponding A record FQDN
      }
    }
    dependsOn: [ recordSetA]
  }
]

 output fqdnList array = [for record in aRecords: '${record.name}.${dnsZoneName}']
 output cn_name string = cn_name

