using '../../azure-resources/virtual-machine-scaleset/main.bicep'

//==========================//
// OSB Params               //
//==========================//
param subscriptionId = 'bd341354-d4c1-4de2-996f-6228b587337c'
param tierName = 'tier'
param environment = 'dev'
param location = 'eastus'
param region = location
param appName = 'ap1'
param shortAppName = ''
param shortEnvironmentName = ''
param appNameSanitized  = ''
param shortTierName = ''
param osbOutputSecretName = sys.readEnvironmentVariable('osbOutputSecretName', 'osb-output-secret') ?? 'osb-output-secret'
param osbOutputKeyvault = 'osb-azureo-scylr-Appkv' 
param osbOutputKeyvaultRgName = 'keyvaults-OSB-azure-osb-work-dev-eastus'
param osbOutputKeyvaultSubscriptionId  = 'f4c62d70-ae3c-4d1f-8647-948936044ff8'
param privateEndpointSubnetId = ''
param subscriptionName = ''
param logWorkspaceId = ''
param minInstances = 1
param maxInstances = 5
param size = ''
param tags = {}
param skuName = 'Standard_D2S_v3'
param storage = 60
param applicationenvironment = ''
param groupIds =[]
param visibilitySubscriptionId ='*'
param networkResourceGroup = ''

//===================//
// VMSS Bicep Params  //
//===================//

// param SIG_rg  = 'persistent-pgtest1-sn-nonp-nonp-eastus'
param image_name = 'mc_rhel8_java8'
param imageVersion ='7.94.0'

param existinggalleryname = '${tierName}${location}sharedgallery'

var imagesubscriptionId = tierName == 'work' ? '58ac996b-18bf-4b6b-913b-6d963ee15fb3' : tierName == 'nonp' ? '5d8e66b0-6ec3-4f57-9768-dce27cc8bef9' : tierName == 'prod' ? '6763ba4d-c6ad-4b62-bc9e-4f5d1571c6c8' :'invalid-subscription'
param imageReference = {
    id: '/subscriptions/${imagesubscriptionId}/resourceGroups/rg-${tierName}-${location}-sharedgallery/providers/Microsoft.Compute/galleries/${tierName}${location}sharedgallery/images/${image_name}/versions/${imageVersion}'
}

//param plan = {}
param plan = {
    name: 'rh-rhel8'
    product: 'rh-rhel'
    publisher: 'redhat'
}
//param plan = {
 // name: 'mc_base_centos_7'
  //product: 'mc_base_centos_7_offer'
  //publisher: 'Mastercard'
//}
//OSdisk param //
param osdiskcreateOption = 'fromImage'
param osdiskSizeGB = '80'
param storageAccountType = 'Standard_LRS'
param osDisk = {}

param dataDisks = []
//datadisk params//
param datadiskSizeGB = 128//256
param datadiskcreateOption = 'Empty'
param caching = 'ReadWrite'//'ReadOnly'
param ultraSSDEnabled = false
param adminUsername = 'azureuser'
param customData = ''
param roleAssignments = null
param scaleSetFaultDomain = 1
param proximityPlacementGroupResourceId = ''
param vmPriority = 'Regular'
param enableEvictionPolicy = false
param maxPriceForLowPriorityVm = ''
param licenseType = ''
param extensionDomainJoinPassword = ''
param extensionDomainJoinConfig = {
  enabled: false
}
param extensionAntiMalwareConfig = {
  enabled: true
}
param extensionMonitoringAgentConfig = {
  enabled: false
}
param monitoringWorkspaceId = '${centralLADWorkspaceId}'
param extensionDependencyAgentConfig = {
  enabled: false
}
param extensionNetworkWatcherAgentConfig = {
  enabled: false
}
param extensionAzureDiskEncryptionConfig = {
  enabled: false
}
param extensionDSCConfig = {
  enabled: false
}
param extensionCustomScriptConfig = {
  enabled: false
  fileData: []
}
param bootDiagnosticStorageAccountUri = ''
param bootDiagnosticStorageAccountName = ''
param diagnosticSettings = [
  {
  name: '${appName}-diagnostic-settings'
  logAnalyticsDestinationType: 'AzureDiagnostics'
  workspaceResourceId: logWorkspaceId//'/subscriptions/1e3fd2bd-6171-4f89-b039-8d2ecee852d3/resourceGroups/cloudcore-logstorage-work-eastus/providers/Microsoft.OperationalInsights/workspaces/eastus-work-log-workspace'
  }
]
param lock = null
// param upgradePolicyMode = 'Automatic'
param enableCrossZoneUpgrade = false
param maxSurge = false
param prioritizeUnhealthyInstances = false
param rollbackFailedInstancesOnPolicyBreach = false
param maxBatchInstancePercent = 20
param maxUnhealthyInstancePercent = 20
param maxUnhealthyUpgradedInstancePercent = 20
param pauseTimeBetweenBatches = 'PT0S'
param enableAutomaticOSUpgrade = false
param disableAutomaticRollback = false
param automaticRepairsPolicyEnabled = false
param gracePeriod = 'PT30M'
param vmNamePrefix = 'vmssvm'
param orchestrationMode = 'Flexible'
param provisionVMAgent = true
param enableAutomaticUpdates = true
param timeZone = ''
param additionalUnattendContent = []
param winRM = {}
param disablePasswordAuthentication = true
param publicKeys = []
param secrets = []
param scheduledEventsProfile = {}
param overprovision = false
param doNotRunExtensionsOnOverprovisionedVMs = false
param zoneBalance = false
param singlePlacementGroup = false
param scaleInPolicy = {
  rules: [
    'Default'
  ]
}
param availabilityZones = [
  1
  2
  3
]
param enableTelemetry = true
param osType = 'Linux'
param baseTime = '' /* TODO : please fix the value assigned to this parameter `utcNow()` */
param sasTokenValidityLength = 'PT8H'
param managedIdentities = { 
  systemAssigned: false
}
param backendPort1 = 8080
param backendPort2 = 8080
param frontendPort1 = 443
param frontendPort2 = 443
param idleTimeoutInMinute1 = 4
param idleTimeoutInMinute2 = 4
//Shared image gallery name
// param galleryName = 'vmssimageGallery'

// ===============================//
//   Diagnostic Settings Params   //
// ==============================//
param centralLADWorkspaceId = logWorkspaceId//'/subscriptions/1e3fd2bd-6171-4f89-b039-8d2ecee852d3/resourceGroups/cloudcore-logstorage-work-eastus/providers/Microsoft.OperationalInsights/workspaces/eastus-work-log-workspace'

//==========================//
// Diskset Encrption Params //
//==========================//
param rotationToLatestKeyVersionEnabled = false
param encryptionType = 'EncryptionAtRestWithPlatformAndCustomerKeys'
param federatedClientId = 'None'

// ========= Key Vault Params BEGIN ========== //
param tenantId = 'f06fa858-824b-4a85-aacb-f372cfdc282e'
param kvpublicNetworkAccess = 'Disabled'
// param kvRoleAssignments = ''
param kvDESPrivateEndpoints = [
  {
    subnetResourceId: privateEndpointSubnetId 
  }
]
param kvAppPrivateEndpoints = [
  {
    subnetResourceId: privateEndpointSubnetId 
  }
]
param enableVaultForTemplateDeployment = true
param enableVaultForDiskEncryption = true
param enableRbacAuthorization = false
param kvCreateMode = 'default'
param kvSku = 'premium'
param encryptionAtHost = false
param securityType = ''
param secureBootEnabled = false
param vTpmEnabled = false

// ========= Key Vault Params END ========== //
// datadisk 
param datadiskcount = 2

//==========================//
//     SSH Key Params       //
//==========================//
param ssh_key = ''
param sshPublicKey = 'sshpublickey'
param sshDeploymentScriptName = 'sshdeploymentscript'


//===================//
// datacollection param Params  //
//===================//

param dcrRgName = 'cloudcore-logstorage-${tierName}-${location}'
param syslogDcrName = 'dcr-vmss-${tierName}-${location}'//'syslog-dcr'
param vmssConfigs = [
  {
    name: 'green'
    instanceCount: 0
    subnetId: privateEndpointSubnetId 
    zones: []
    // backendPoolName: '${vmssName}-backendpool01' #vmsstest
    backendPoolName: 'backendpool01' 
    // vmssname: 'msms-vmss-01'
  }
  {
    name: 'blue'
    instanceCount: 0
    subnetId: privateEndpointSubnetId 
    zones: []
    // backendPoolName: '${vmssName}-backendpool02' #vmsstest
    backendPoolName: 'backendpool02' 
    // vmssname: 'msms-vmss-02'
  }

]
param resourceType  = 'vmss'
var vmssName = '${resourceType}-${appName}-${tierName}-${environment}-${location}'
// param storageAccountCSEFileName = 'bootstrap.sh'

// var lb01PrivateIP = ''
// var lb02PrivateIP = ''
//===================//
// load balancer param Params  //
//===================//
// param frontendIPConfigs  = [
//   {
//     name: '${vmssName}-privipconfigplb01'
//     subnetId: privateEndpointSubnetId //'/subscriptions/bd341354-d4c1-4de2-996f-6228b587337c/resourceGroups/network-AzureForgePOC-work-eastus/providers/Microsoft.Network/virtualNetworks/AzureForgePOCworkeastusvnet/subnets/snet-private'
//     privateIPAddress: 'lb01PrivateIP'//DONOT modifty this string to be replaced in vmss main.bicep 
//     privateIPAllocationMethod: 'Static'
//   }
//   {
//     name: '${vmssName}-privipconfigplb02'
//     subnetId: privateEndpointSubnetId //'/subscriptions/bd341354-d4c1-4de2-996f-6228b587337c/resourceGroups/network-AzureForgePOC-work-eastus/providers/Microsoft.Network/virtualNetworks/AzureForgePOCworkeastusvnet/subnets/snet-private'
//     privateIPAddress: 'lb02PrivateIP' //DONOT modifty this string to be replaced in vmss main.bicep
//     privateIPAllocationMethod: 'Static'
//   }
// ]
//param vmssautoscale  = []
 param vmssautoscale = [
  {
    name: '${vmssName}-01'
    min: 1
    max: 10
    default: 1
    cpuIncrease: 80
    cpuDecrease: 30
    memoryIncrease: 30
    memoryDecrease: 70
  }
    {
    name: '${vmssName}-01'
    min: 1
    max: 10
    default: 1
    cpuIncrease: 80
    cpuDecrease: 30
    memoryIncrease: 30
    memoryDecrease: 70
  }
]


param probes  = [
  {
    name: 'vmss-probe01'
    intervalInSeconds: 15
    numberOfProbes: 2
    port: 80
    protocol: 'Tcp'
  }
]

//===================//
// DNS Record  Params  //
//===================//
param dnsZoneName  = 'mastercard.int' //'az.mastercard.local'
param ttl  = 10
// param aRecords  = [
//   {
//     name: '${appName}' // 'authnz360.dev.eastus.7246827ts28100401'
//     ips: [
//       // '10.1.169.244'
//      '10.1.169.245'
//     ]
//   }
//   {
//     name: '${environment}.${appName}'//'dev.authnz360'
//     ips: [
//      '10.1.169.244'
//     ]
//   }
// ]
param cn_name  = ''
param cnameTarget = 'az.mastercard.local' 
param associationName  = 'vmssdcrassociation'
//===================//
// container inside infra SA param Params  //
//===================//
param containerName  = 'vmsscontainer'
param blobServices = {
  name: 'default'
  containers: [
    {
    name: containerName //'${shortAppName}-ctner' 
    }
  ]
  diagnosticSettings: [{     
        name: '${appName}-diagnostic-settings'
        logAnalyticsDestinationType: 'AzureDiagnostics'
        workspaceResourceId: logWorkspaceId
        metricCategories: [
          {
            category: 'AllMetrics'
          }
        ]
      }]
    deleteRetentionPolicy: {
      enabled: true
      days: 6
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    logging: {
      delete: true
      read: false
      write: true
      retentionPolicy: {
        days: 30
      }
    }
    versioning: {
      enabled: true
    }
}


param healthExtensionConfigs = [
  {
    // vmssName: 'msms-vmss-01'//'${vmssName}-green'
    osType: 'Linux'
    settings: {
      protocol: 'http'
      port: 8080
      requestPath: '/health'
      intervalInSeconds: 10
      numberOfProbes: 3
      gracePeriod: 30
      typeHandlerVersion: '2.0'
      autoUpgradeMinorVersion: true
    }
  }
  {
    // vmssName: 'msms-vmss-02'//'${vmssName}-blue'
    osType: 'Linux'
    settings: {
      protocol: 'http'
      port: 8080
      requestPath: '/health'
      intervalInSeconds: 10
      numberOfProbes: 3
      gracePeriod: 30
      typeHandlerVersion: '2.0'
      autoUpgradeMinorVersion: true
    }
  }
]
 




