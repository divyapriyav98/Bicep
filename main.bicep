metadata name = 'Azure Virtual Machine Scale Set'
metadata description = 'This module deploys an Azure Virtual Machine Scale Set.'

//================================//
// OSB Required Convention Params //
//================================//

@description('Required. Azure Subscription ID')
param subscriptionId string

@description('Required. Specifies the appName of the VMSS naming convention.')
param appName string 

@description('Required. Specifies the tierName of the VMSS naming convention.')
param tierName string 

@description('Required. Specifies the environment of the VMSS naming convention.')
param environment string

@description('Optional,PrivateEndpoint subnet Id')
param privateEndpointSubnetId string = ''
@description('Required. Specifies the region of the VMSS.')
param location string = ''
param region string = location

param customTags object = {}

@description('Required. Tags of the VMSS.')
param tags object?

param image_name string = ''

param storage int  

@description('Required. The size of the VMSS SKU.')
param size string = 'small'

@description('Required. Specifies the minimum auto scale of the VMSS.')
param minInstances int?

param maxInstances int?

param shortTierName string = ''

param appNameSanitized string = ''

param shortAppName string = ''

param shortEnvironmentName string = ''

@description('Service name')
param serviceName string = 'avms'

@description('Sanitized location string, e.g. "eu" for East US.')
param locationSanitized string = 'eu'

@description('Required. KeyVault to send output for OSB')
param osbOutputKeyvault string = ''

@description('Required. Resource Group Name of OSB KeyVault')
param osbOutputKeyvaultRgName string = ''

@description('Required. OSB KeyVault Subscription Id')
param osbOutputKeyvaultSubscriptionId string = ''

@description('Required. Azure Devops Pipeline Run ID and BuildID, for eg, 31-1435')
param osbOutputSecretName string = ''

@description('Required. Azure Subscription Name')
param subscriptionName string

@description('Required. Azure Log Analytics WorkspaceID')
param logWorkspaceId string

// ======================== //
// OSB Processor Parameters //
// ======================== //
@description('Required. The SKU size of the VMs.')
param skuName string

// ==================== //
// KeyVault Parameters  //
// ==================== //
@description('Optional. All access policies to create.')
param accessPolicies accessPoliciesType

@description('Optional. All secrets to create.')
param secrets secretsType?

@description('Optional. All keys to create in DES KeyVaults.')
param DESkeys keysType?

@description('Optional. All keys to create in App KeyVaults.')
param Appkeys keysType?

@description('Optional. Specifies if the vault is enabled for deployment by script or compute.')
param enableVaultForDeployment bool = true

@description('Optional. Specifies if the vault is enabled for a template deployment.')
param enableVaultForTemplateDeployment bool = true

@description('Optional. Specifies if the azure platform has access to the vault for enabling disk encryption scenarios.')
param enableVaultForDiskEncryption bool = true

@description('Optional. Switch to enable/disable Key Vault\'s soft delete feature.')
param enableSoftDelete bool = true

@description('Optional. softDelete data retention days. It accepts >=7 and <=90.')
param softDeleteRetentionInDays int = 7

@description('Optional. Property that controls how data actions are authorized. When true, the key vault will use Role Based Access Control (RBAC) for authorization of data actions, and the access policies specified in vault properties will be ignored. When false, the key vault will use the access policies specified in vault properties, and any policy stored on Azure Resource Manager will be ignored. Note that management actions are always authorized with RBAC.')
param enableRbacAuthorization bool = true

@description('Optional. The vault\'s create mode to indicate whether the vault need to be recovered or not. - recover or default.')
param kvCreateMode string = 'default'

@description('Optional. Provide \'true\' to enable Key Vault\'s purge protection feature.')
param enablePurgeProtection bool = true

@description('Optional. Specifies the SKU for the vault.')
@allowed([
  'premium'
  'standard'
])
param kvSku string = 'premium'

@description('Optional. Rules governing the accessibility of the resource from specific network locations.')
param networkAcls object?

@description('Optional. Whether or not public network access is allowed for this resource. For security reasons it should be disabled. If not specified, it will be disabled by default if private endpoints are set and networkAcls are not set.')
@allowed([
  ''
  'Enabled'
  'Disabled'
])
param kvpublicNetworkAccess string = 'Disabled'

@description('Optional. Array of role assignments to create.')
param kvRoleAssignments roleAssignmentType

@description('Optional. Configuration details for private endpoints. For security reasons, it is recommended to use private endpoints whenever possible.')
param kvDESPrivateEndpoints privateEndpointType

@description('Optional. Configuration details for private endpoints. For security reasons, it is recommended to use private endpoints whenever possible.')
param kvAppPrivateEndpoints privateEndpointType

@description('Optional. The diagnostic settings of the service.')
param kvDiagnosticSettings diagnosticSettingType

@description('Optional. Tenant id of the Scale Set.')
param tenantId string = ''

//==========================//
//     SSH Key Params       //
//==========================//

@description('Optional. The list of SSH public keys used to authenticate with linux based VMs.')
param publicKeys array = []

@description('Name of the SSH Public Key.')
param sshPublicKey string = ''

@description('Required. The name of the Deployment Script to create for the SSH Key generation.')
param sshDeploymentScriptName string = ''

// =========================== //
// Managed Identity Parameters //
// =========================== //
@description('Optional. The federated identity credentials list to indicate which token from the external IdP should be trusted by your application. Federated identity credentials are supported on applications only. A maximum of 20 federated identity credentials can be added per application object.')
param federatedIdentityCredentials federatedIdentityCredentialsType

@description('Optional. Array of role assignments to create.')
param umiRoleAssignments roleAssignmentType

//=========================== //
//Storage Accounts Parameters //
//=========================== //
@description('Optional. Blob service and containers to deploy.')
param blobServices object = saKind != 'FileStorage'
  ? {
      containerDeleteRetentionPolicyEnabled: true
      containerDeleteRetentionPolicyDays: 7
      deleteRetentionPolicyEnabled: true
      deleteRetentionPolicyDays: 7
    }
  : {}

@description('Conditional. If true, enables Hierarchical Namespace for the storage account. Required if enableSftp or enableNfsV3 is set to true.')
param enableHierarchicalNamespace bool = false

@allowed([
  'Storage'
  'StorageV2'
  'BlobStorage'
  'FileStorage'
  'BlockBlobStorage'
])
@description('Optional. Type of Storage Account to create.')
param saKind string = 'StorageV2'

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GZRS'
  'Standard_RAGZRS'
])
@description('Optional. Storage Account Sku Name.')
param saSkuName string = 'Standard_LRS'

@allowed([
  'Premium'
  'Hot'
  'Cool'
])
@description('Conditional. Required if the Storage Account kind is set to BlobStorage. The access tier is used for billing. The "Premium" access tier is the default value for premium block blobs storage account type and it cannot be changed for the premium block blobs storage account type.')
param saAccessTier string = 'Hot'

@description('Optional. Array of role assignments to create.')
param saRoleAssignments roleAssignmentType



@description('Optional. The diagnostic settings of the service.')
param saDiagnosticSettings diagnosticSettingType

@description('Optional. The customer managed key definition.')
param saCustomerManagedKey customerManagedKeyType

// ============================= //
// Autoscale Settings Parameters //
// ============================= //
@description('Required. Autoscale Name.')
param autoScaleName string = 'autoScaleSettings'

@description('Required. State of Autoscale.')
param autoScaleEnabled bool = true

@description('Required. Autoscale Profile Name.')
param autoScaleProfile string = 'vmssautoscaleprofile'

@description('Required. Default instance count.')
param defaultInstances string = '1'
param datadiskcount int =1

//==========================//
// Diskset Encrption Params //
//==========================//
@description('Optional. The type of key used to encrypt the data of the disk. For security reasons, it is recommended to set encryptionType to EncryptionAtRestWithPlatformAndCustomerKeys.')
@allowed([
  'EncryptionAtRestWithCustomerKey'
  'EncryptionAtRestWithPlatformAndCustomerKeys'
])
param encryptionType string = 'EncryptionAtRestWithPlatformAndCustomerKeys'

@description('Optional. Multi-tenant application client ID to access key vault in a different tenant. Setting the value to "None" will clear the property.')
param federatedClientId string = ''

@description('Optional. Set this flag to true to enable auto-updating of this disk encryption set to the latest key version.')
param rotationToLatestKeyVersionEnabled bool = false


//==========================//
// VMSS Bicep Params         //
//==========================//
@description('Optional. This property can be used by user in the request to enable or disable the Host Encryption for the virtual machine. This will enable the encryption for all the disks including Resource/Temp disk at host itself. For security reasons, it is recommended to set encryptionAtHost to True. Restrictions: Cannot be enabled if Azure Disk Encryption (guest-VM encryption using bitlocker/DM-Crypt) is enabled on your virtual machine scale sets.')
param encryptionAtHost bool = true

@description('Optional. Specifies the SecurityType of the virtual machine scale set. It is set as TrustedLaunch to enable UefiSettings.')
param securityType string = ''

@description('Optional. Specifies whether secure boot should be enabled on the virtual machine scale set. This parameter is part of the UefiSettings. SecurityType should be set to TrustedLaunch to enable UefiSettings.')
param secureBootEnabled bool = false

@description('Optional. Specifies whether vTPM should be enabled on the virtual machine scale set. This parameter is part of the UefiSettings.  SecurityType should be set to TrustedLaunch to enable UefiSettings.')
param vTpmEnabled bool = false

@description('Required. OS image reference. In case of marketplace images, it\'s the combination of the publisher, offer, sku, version attributes. In case of custom images it\'s the resource ID of the custom image.')
param imageReference object

@description('Optional. Specifies information about the marketplace image used to create the virtual machine. This element is only used for marketplace images. Before you can use a marketplace image from an API, you must enable the image for programmatic use.')
param plan object = {}

@description('Required. Specifies the OS disk. For security reasons, it is recommended to specify DiskEncryptionSet into the osDisk object. Restrictions: DiskEncryptionSet cannot be enabled if Azure Disk Encryption (guest-VM encryption using bitlocker/DM-Crypt) is enabled on your VM Scale sets.')
param osDisk object

@description('Optional. Specifies the data disks. For security reasons, it is recommended to specify DiskEncryptionSet into the dataDisk object. Restrictions: DiskEncryptionSet cannot be enabled if Azure Disk Encryption (guest-VM encryption using bitlocker/DM-Crypt) is enabled on your VM Scale sets.')
param dataDisks array = []

@description('Optional. The flag that enables or disables a capability to have one or more managed data disks with UltraSSD_LRS storage account type on the VM or VMSS. Managed disks with storage account type UltraSSD_LRS can be added to a virtual machine or virtual machine scale set only if this property is enabled.')
param ultraSSDEnabled bool = false

@description('Required. Administrator username.')
@secure()
param adminUsername string

@description('Optional. Custom data associated to the VM, this value will be automatically converted into base64 to account for the expected VM format.')
param customData string = ''

@description('Optional. Array of role assignments to create.')
param roleAssignments roleAssignmentType

@description('Optional. Fault Domain count for each placement group.')
param scaleSetFaultDomain int = 1

@description('Optional. Resource ID of a proximity placement group.')
param proximityPlacementGroupResourceId string = ''

@description('Required. Configures NICs and PIPs.')
param nicConfigurations array = []

@description('Optional. Specifies the priority for the virtual machine.')
@allowed([
  'Regular'
  'Low'
  'Spot'
])
param vmPriority string = 'Regular'

@description('Optional. Specifies the eviction policy for the low priority virtual machine. Will result in \'Deallocate\' eviction policy.')
param enableEvictionPolicy bool = false

@description('Optional. Specifies the maximum price you are willing to pay for a low priority VM/VMSS. This price is in US Dollars.')
param maxPriceForLowPriorityVm string = ''

@description('Optional. Specifies that the image or disk that is being used was licensed on-premises. This element is only used for images that contain the Windows Server operating system.')
@allowed([
  'Windows_Client'
  'Windows_Server'
  ''
])
param licenseType string = ''

@description('Optional. Required if name is specified. Password of the user specified in user parameter.')
@secure()
param extensionDomainJoinPassword string = ''

@description('Optional. The configuration for the [Domain Join] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionDomainJoinConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [Anti Malware] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionAntiMalwareConfig object = {
  enabled: true
}

@description('Optional. The configuration for the [Monitoring Agent] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionMonitoringAgentConfig object = {
  enabled: false
}

@description('Optional. Resource ID of the monitoring log analytics workspace.')
param monitoringWorkspaceId string = ''

@description('Optional. The configuration for the [Dependency Agent] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionDependencyAgentConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [Network Watcher Agent] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionNetworkWatcherAgentConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [Azure Disk Encryption] extension. Must at least contain the ["enabled": true] property to be executed. Restrictions: Cannot be enabled on disks that have encryption at host enabled. Managed disks encrypted using Azure Disk Encryption cannot be encrypted using customer-managed keys.')
param extensionAzureDiskEncryptionConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [Desired State Configuration] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionDSCConfig object = {
  enabled: false
}

@description('Optional. The configuration for the [Custom Script] extension. Must at least contain the ["enabled": true] property to be executed.')
param extensionCustomScriptConfig object = {
  enabled: false
  fileData: []
}

@description('Optional. Storage account boot diagnostic base URI.')
param bootDiagnosticStorageAccountUri string = '.blob.${az.environment().suffixes.storage}/'

@description('Optional. Storage account used to store boot diagnostic information. Boot diagnostics will be disabled if no value is provided.')
param bootDiagnosticStorageAccountName string = ''

@description('Optional. The diagnostic settings of the service.')
param diagnosticSettings diagnosticSettingType

@description('Optional. The lock settings of the service.')
param lock lockType

@description('Optional. Specifies the mode of an upgrade to virtual machines in the scale set.\' Manual - You control the application of updates to virtual machines in the scale set. You do this by using the manualUpgrade action. ; Automatic - All virtual machines in the scale set are automatically updated at the same time. - Automatic, Manual, Rolling.')
@allowed([
  'Manual'
  'Automatic'
  'Rolling'
])
param upgradePolicyMode string = 'Manual'

@description('Optional. Allow VMSS to ignore AZ boundaries when constructing upgrade batches. Take into consideration the Update Domain and maxBatchInstancePercent to determine the batch size.')
param enableCrossZoneUpgrade bool = false

@description('Optional. Create new virtual machines to upgrade the scale set, rather than updating the existing virtual machines. Existing virtual machines will be deleted once the new virtual machines are created for each batch.')
param maxSurge bool = false

@description('Optional. Upgrade all unhealthy instances in a scale set before any healthy instances.')
param prioritizeUnhealthyInstances bool = false

@description('Optional. Rollback failed instances to previous model if the Rolling Upgrade policy is violated.')
param rollbackFailedInstancesOnPolicyBreach bool = false

@description('Optional. The maximum percent of total virtual machine instances that will be upgraded simultaneously by the rolling upgrade in one batch. As this is a maximum, unhealthy instances in previous or future batches can cause the percentage of instances in a batch to decrease to ensure higher reliability.')
param maxBatchInstancePercent int = 20

@description('Optional. The maximum percentage of the total virtual machine instances in the scale set that can be simultaneously unhealthy, either as a result of being upgraded, or by being found in an unhealthy state by the virtual machine health checks before the rolling upgrade aborts. This constraint will be checked prior to starting any batch.')
param maxUnhealthyInstancePercent int = 20

@description('Optional. The maximum percentage of the total virtual machine instances in the scale set that can be simultaneously unhealthy, either as a result of being upgraded, or by being found in an unhealthy state by the virtual machine health checks before the rolling upgrade aborts. This constraint will be checked prior to starting any batch.')
param maxUnhealthyUpgradedInstancePercent int = 20

@description('Optional. The wait time between completing the update for all virtual machines in one batch and starting the next batch. The time duration should be specified in ISO 8601 format.')
param pauseTimeBetweenBatches string = 'PT0S'

@description('Optional. Indicates whether OS upgrades should automatically be applied to scale set instances in a rolling fashion when a newer version of the OS image becomes available. Default value is false. If this is set to true for Windows based scale sets, enableAutomaticUpdates is automatically set to false and cannot be set to true.')
param enableAutomaticOSUpgrade bool = false

@description('Optional. Whether OS image rollback feature should be disabled.')
param disableAutomaticRollback bool = false

@description('Optional. Specifies whether automatic repairs should be enabled on the virtual machine scale set.')
param automaticRepairsPolicyEnabled bool = false

@description('Optional. The amount of time for which automatic repairs are suspended due to a state change on VM. The grace time starts after the state change has completed. This helps avoid premature or accidental repairs. The time duration should be specified in ISO 8601 format. The minimum allowed grace period is 30 minutes (PT30M). The maximum allowed grace period is 90 minutes (PT90M).')
param gracePeriod string = 'PT30M'

@description('Optional. Specifies the computer name prefix for all of the virtual machines in the scale set.')
@minLength(1)
@maxLength(15)
param vmNamePrefix string = 'vmssvm'

@description('Optional. Specifies the orchestration mode for the virtual machine scale set.')
@allowed([
  'Flexible'
  'Uniform'
])
param orchestrationMode string = 'Flexible'

@description('Optional. Indicates whether virtual machine agent should be provisioned on the virtual machine. When this property is not specified in the request body, default behavior is to set it to true. This will ensure that VM Agent is installed on the VM so that extensions can be added to the VM later.')
param provisionVMAgent bool = true

@description('Optional. Indicates whether Automatic Updates is enabled for the Windows virtual machine. Default value is true. For virtual machine scale sets, this property can be updated and updates will take effect on OS reprovisioning.')
param enableAutomaticUpdates bool = true

@description('Optional. Specifies the time zone of the virtual machine. e.g. \'Pacific Standard Time\'. Possible values can be `TimeZoneInfo.id` value from time zones returned by `TimeZoneInfo.GetSystemTimeZones`.')
param timeZone string = ''

@description('Optional. Specifies additional base-64 encoded XML formatted information that can be included in the Unattend.xml file, which is used by Windows Setup. - AdditionalUnattendContent object.')
param additionalUnattendContent array = []

@description('Optional. Specifies the Windows Remote Management listeners. This enables remote Windows PowerShell. - WinRMConfiguration object.')
param winRM object = {}

@description('Optional. Specifies whether password authentication should be disabled.')
#disable-next-line secure-secrets-in-params // Not a secret
param disablePasswordAuthentication bool = true

@description('Optional. Specifies Scheduled Event related configurations.')
param scheduledEventsProfile object = {}

@description('Optional. Specifies whether the Virtual Machine Scale Set should be overprovisioned.')
param overprovision bool = false

@description('Optional. When Overprovision is enabled, extensions are launched only on the requested number of VMs which are finally kept. This property will hence ensure that the extensions do not run on the extra overprovisioned VMs.')
param doNotRunExtensionsOnOverprovisionedVMs bool = false

@description('Optional. Whether to force strictly even Virtual Machine distribution cross x-zones in case there is zone outage.')
param zoneBalance bool = false

@description('Optional. When true this limits the scale set to a single placement group, of max size 100 virtual machines. NOTE: If singlePlacementGroup is true, it may be modified to false. However, if singlePlacementGroup is false, it may not be modified to true.')
param singlePlacementGroup bool = false

@description('Optional. Specifies the scale-in policy that decides which virtual machines are chosen for removal when a Virtual Machine Scale Set is scaled-in.')
param scaleInPolicy object = {
  rules: [
    'Default'
  ]
}

@description('Optional. The initial instance count of scale set VMs.')
param skuCapacity int = 1

@description('Optional. The virtual machine scale set zones. NOTE: Availability zones can only be set when you create the scale set.')
param availabilityZones array = [1, 2, 3]

@description('Optional. Enable/Disable usage telemetry for module.')
param enableTelemetry bool = true

@description('Required. The chosen OS type.')
@allowed([
  'Windows'
  'Linux'
])
param osType string

@description('Generated. Do not provide a value! This date value is used to generate a registration token.')
param baseTime string = utcNow('d')

@description('Optional. SAS token validity length to use to download files from storage accounts. Usage: \'PT8H\' - valid for 8 hours; \'P5D\' - valid for 5 days; \'P1Y\' - valid for 1 year. When not provided, the SAS token will be valid for 8 hours.')
param sasTokenValidityLength string = 'PT8H'

@description('Optional. The managed identity definition for this resource.')
param managedIdentities managedIdentitiesType

// ===============================//
//   Diagnostic Settings Params   //
// ==============================//

@description('Optional. The Log Analytics Workspace ID.')
param centralLADWorkspaceId string = ''
// ===============================//
//   OSDisk Params   //
// ==============================//

param osdiskcreateOption string?
param osdiskSizeGB string?
param storageAccountType string?

//datadisk params //
param caching string?
param datadiskcreateOption string?
param datadiskSizeGB int?


// ================ //
// Other Params     //
// ================ //

@description('Optional. Type of resource.')
param resourceType string = 'vmss'

// param dataCollectionRulesName string = 'vmssdatacollectionrules'
param associationName string //'vmssdcrassociation'
param bootstrapCustomScriptURL string = '' 

param commandToExecute string = ''
// data collection params
param syslogDcrName string
// param dcrSubscriptionId string
param dcrRgName string 
param vmssConfigs array
param skuTier string = 'Standard' // Defaulted, but overridable
param zones array = [] // Optional, pass if using AZs
param extensionHealthConfig object = {
  enabled: true
  settings: {
   protocol: 'http'
   port: 80
   requestPath: '/'
}
}

// param frontendIPConfigs array
param probes array
param healthExtensionConfigs array
param dnsZoneName string 
param ttl int 
// param aRecords array
param vmssautoscale array
// ============== //
//   CNAME       //
// ============== //
param cn_name string
param cnameTarget string
// ============== //
//   SSH KEY      //
// ============== //

param ssh_key string = ''

var loadBalancerResourceId = deployLB ?loadBalancer.outputs.resourceId : ''

param existinggalleryname string
var rawName = 'vmssimageGallery_${resourceGroupBase}'
var galleryName = toLower(replace(replace(rawName, '-', ''), ' ', ''))
@description('Optional. Configuration details for private endpoints. For security reasons, it is recommended to use private endpoints whenever possible.')
param saPrivateEndpoints privateEndpointType
param imageVersion string 
param backendPort1 int
param backendPort2 int
param frontendPort1 int
param frontendPort2 int
param idleTimeoutInMinute1 int
param idleTimeoutInMinute2 int



// ============== //
//   Variables    //
// ============== //

var vmsspwd = '${resourceType}-${appName}-${tierName}-${environment}-${location}'
// Convert the unique string to a set of characters for KV Names
var alphabet = 'abcdefghijklmnopqrstuvwxyz'
var digits = '0123456789'
// var randomString = uniqueString(keyvaultsRgName, digits, alphabet)
var vmPassword = uniqueString(vmsspwd, digits, alphabet)
var transientRgName = 'transient-${tags!.applicationEnvironment}-${tags!.hostingEnvironment}-${location}'
var persistentRgName = 'persistent-${tags!.applicationEnvironment}-${tags!.hostingEnvironment}-${location}'
var keyvaultsRgName = 'keyvaults-${tags!.applicationEnvironment}-${tags!.hostingEnvironment}-${location}'
var umiNameprefix = '${appName}-kb-${tierName}-${environment}-${location}'			
var umiNameSuffix = '-msi'
var umiName = length(umiNameprefix) + length(umiNameSuffix) <= 128 ? '${umiNameprefix}${umiNameSuffix}' : '${substring(umiNameprefix, 0, 124 - length(umiNameSuffix))}${umiNameSuffix}'	
var saMcName = length(baseSaName) <= 22 ? 'st${baseSaName}': 'st${substring('${baseSaName}', 0, 15)}'
var resourceGroupUniqueIdentifier = uniqueString(daUniqueString, digits, alphabet) 

// Generate unique identifiers using values from tags
var daUniqueString = uniqueString(tags!.serviceInstanceId, tags!.Program_UUID, tags!.DeployableAsset_UUID, tags!.TechnicalAsset_UUID, tags!.Product_UUID)
var taUniqueString = uniqueString(tags!.Program_UUID, tags!.TechnicalAsset_UUID, tags!.Product_UUID)
var productUniqueString = uniqueString(tags!.Program_UUID, tags!.Product_UUID)

// Generate service identifier from combined identifiers
var serviceIdentifier = substring(uniqueString(daUniqueString, taUniqueString, productUniqueString), 0, 9)
var serviceIdentifierShort = substring(serviceIdentifier, 0, 4)
var baseSaName = substring(toLower('${serviceIdentifierShort}${resourceGroupUniqueIdentifier}'),0,17)
var resourceGroupBase = '${serviceIdentifier}-${serviceName}-${tags!.applicationEnvironment}-${tags!.hostingEnvironment}-${location}'

var subnetParts = split(privateEndpointSubnetId, '/')
var  subnetname = subnetParts[10] // index 10 = subnet name
var virtualnetwork = subnetParts[8] // index 8 = vnet name
var vnetRG = subnetParts[4]       // Extracts RG name
// Take first 9 parts to exclude the last two: ['subnets', 'yourSubnetName']
var vnetId = join(take(subnetParts, 9), '/')
var lb01PrivateIP = subnetIPcheck.outputs.availableIP1
var lb02PrivateIP = subnetIPcheck.outputs.availableIP2

var logWorkspaceIdParts = split(logWorkspaceId, '/')
var dcrSubscriptionId = logWorkspaceIdParts[2]
param containerName  string
var deployLB  = LBExistenceCheck.outputs.deployLB
var loadBalancerExists  = LBExistenceCheck.outputs.loadBalancerExists


// Merge both
param certDate string = utcNow('d') 
param networkResourceGroup string
param groupIds array
param visibilitySubscriptionId string
param applicationenvironment string 
var mergedTags = union(tags, additionalTags)
var additionalTags = {
  vmssflexible: 'true'
  VMSSUpgrade: 'false'
  
}
var lbname = '${namingModule.outputs.resourceName}-persistentlb' //loadBalancer.outputs.name
var frontendIpName01 = '${namingModule.outputs.resourceName}-privipconfigplb01'
// var peVnetName  = 'vnet-eastus-${tierName}-mcrouteable-private-endpoint'
var peSubscriptionId = tierName == 'prod'? 'c867858e-2261-4347-b241-fa3d17b40fba': 'ffaa29d0-3efc-4804-847c-6d48627c2b70'
var peResourceGroupName = tierName == 'prod'? 'rg-cloudcore-mcrouteable-private-endpoint-eastus-prod': 'rg-cloudcore-mcrouteable-private-endpoint-eastus-nonp'


@description('Centralized variables for Object Storage module names and scopes')
var vmssModuleSettings = {
  infraGeneric: {
    name: 'mcInfraGeneric-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: az.subscription(subscriptionId)
  }
  namingModule: {
    name: 'generateResourceName-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: az.subscription(subscriptionId)
  }
  vmss: {
    name: 'vmss-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'persistent-${resourceGroupBase}')
  }
  vmssKey: {
    name: 'vmsskey-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'keyvaults-${resourceGroupBase}')
  }
  sshKey: {
    name: 'sshkey-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'persistent-${resourceGroupBase}')
  }
  dnsrecord: {
    name: 'dnsrecord-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'persistent-${resourceGroupBase}')
  }
  dataCollectionRules: {
    name: 'dataCollectionRules-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'persistent-${resourceGroupBase}')
  }
  DES:{
    name: 'DES-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'persistent-${resourceGroupBase}')
  }
  loadbalancer:{
    name: 'loadbalancer-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'persistent-${resourceGroupBase}')
  }
  storageRoleDataReader: {
    name: 'saBlobDataReader-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'persistent-${resourceGroupBase}')
  }
  storageRoleDataContributor: {
    name: 'saBlobDataContributor-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'persistent-${resourceGroupBase}')
  }
  SMBRole: {
    name: 'Storage-File-Data-SMB-Share-Contributor-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'persistent-${resourceGroupBase}')
  }
  outputKeyVaults: {
    name: 'outputKV-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(osbOutputKeyvaultSubscriptionId, osbOutputKeyvaultRgName)
  }
  osimageresourcegroup: {
    name: 'osimagerg-${uniqueString(deployment().name, location, subscriptionId)}'
  }
  healthExtensions: {
    name: 'healthExtensions-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'persistent-${resourceGroupBase}')
  }
  imagegallery: {
    name: 'imagegallery-${uniqueString(deployment().name, location, subscriptionId)}'
    // scope: resourceGroup(subscriptionId, vmssgalleryname)
  }
  SAPrivateendpoint: {
    name: 'SAPrivateendpoint-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'persistent-${resourceGroupBase}')
  }
  autoscale: {
    name: 'autoscale-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, 'persistent-${resourceGroupBase}')
  }
  privatelinkservice: {
    name: 'privateLink-${uniqueString(deployment().name, location, subscriptionId)}'
    scope: resourceGroup(subscriptionId, networkResourceGroup)
  }
  privateEndpoint: {
    name: 'privateEndpoint-${uniqueString(deployment().name, location, peSubscriptionId)}'    
  }
}

// ============== //
// Main Resources //
// ============== //

module namingModule 'br/CoreModules:az-bm-naming:V0.0.1' = {
  name: vmssModuleSettings.namingModule.name
  scope: vmssModuleSettings.namingModule.scope
  params: {
    environment: environment
    tierName: tierName
    location: location
    serviceName: serviceName
    tags: tags
    resourceType:resourceType
  }
}

targetScope = 'subscription'
module infraGeneric 'br/CoreModules:az-bm-mc-infra-generic:V0.1.2' = {
  
  
  params: {
    AppkvName: namingModule.outputs.appKeyVaultName
    DESkvName: namingModule.outputs.desKeyVaultName
    resourceType: resourceType
    kvCreateMode: kvCreateMode
    accessPolicies: accessPolicies
    enablePurgeProtection: enablePurgeProtection
    enableSoftDelete: enableSoftDelete
    enableVaultForDeployment: enableVaultForDeployment
    enableRbacAuthorization: enableRbacAuthorization
    enableVaultForDiskEncryption: enableVaultForDiskEncryption
    enableVaultForTemplateDeployment: enableVaultForTemplateDeployment
    DESkeys: DESkeys
    Appkeys: Appkeys
    kvAppPrivateEndpoints: kvAppPrivateEndpoints
    kvDESPrivateEndpoints: kvDESPrivateEndpoints
    kvDiagnosticSettings: kvDiagnosticSettings
    kvRoleAssignments: kvRoleAssignments
    kvSku: kvSku
    publicNetworkAccess: kvpublicNetworkAccess
    secrets: secrets
    softDeleteRetentionInDays: softDeleteRetentionInDays
    // Resource group parameters
    persistentRgName: namingModule.outputs.persistentRgName
    keyvaultsRgName: namingModule.outputs.keyvaultsRgName
    saName: namingModule.outputs.infraGenericStorageAccountName
    blobServices: blobServices
    enableHierarchicalNamespace: enableHierarchicalNamespace
    kind: saKind
    saAccessTier: saAccessTier
    saPrivateEndpoints: saPrivateEndpoints
    saSkuName: saSkuName
    saCustomerManagedKey: saCustomerManagedKey
    saDiagnosticSettings: saDiagnosticSettings
    saRoleAssignments: saRoleAssignments
    // User Managed Identity parameters
    federatedIdentityCredentials: federatedIdentityCredentials
    umiName: namingModule.outputs.umiName
    umiRoleAssignments: umiRoleAssignments
    // Common parameters
    enableTelemetry: enableTelemetry
    location: location
    lock: lock
    tags: tags
    tierName: tierName
    privateEndpointSubnetId: privateEndpointSubnetId
  }
}


module privatelinkservice 'PrivateEndpoint/privatelinkservice.bicep' = {
  name: vmssModuleSettings.privatelinkservice.name
  scope: vmssModuleSettings.privatelinkservice.scope
  params: {
    privateLinkServiceName: 'pl-${namingModule.outputs.resourceName}'//'pl-bcjenkinshahs-nginx-dev-nonp'
    location: location
    lbFrontendIpId: '/subscriptions/${subscriptionId}/resourceGroups/persistent-${resourceGroupBase}/providers/Microsoft.Network/loadBalancers/${lbname}/frontendIPConfigurations/${frontendIpName01}'    
    plsSubnetId: privateEndpointSubnetId //'/subscriptions/84e759d0-034c-42da-b600-8dfe9d786257/resourceGroups/network-1282-nonp-eastus/providers/Microsoft.Network/virtualNetworks/1282nonpeastusvnet/subnets/snet-private'
    plsIpConfigName: 'snet-private-1'
    visibilitySubscriptionId: '*'
  }
  dependsOn: [loadBalancer]
 
}



module privateendpoint 'PrivateEndpoint/privateendpoint.bicep' = {
  name: vmssModuleSettings.privateEndpoint.name
  scope: resourceGroup(peSubscriptionId, peResourceGroupName)  
  params: {
    location: location
    privateEndpointName:  'pe-${namingModule.outputs.resourceName}'//'pe-bcjenkinshahs-nginx-dev-nonp'
    privateEndpointNicName: 'pe-${namingModule.outputs.resourceName}-nic' //'pe-bcjenkinshahs-nginx-dev-nonp-nic'
    privateLinkServiceId: privatelinkservice.outputs.privateLinkServiceId
    privateLinkConnectionName: 'pe-${namingModule.outputs.resourceName}' //'pe-bcjenkinshahs-nginx-dev-nonp'
    groupIds: []
    tierName: tierName
    
    
  }
  dependsOn: [privatelinkservice]
}


module vmssExtensionModule 'vmssextensions/main.bicep' = [for (config, i) in vmssConfigs: {
  scope: vmssModuleSettings.vmss.scope
  name: 'vmss-vmaccess-extension-${config.name}'
  params: {
    vmssName: '${namingModule.outputs.resourceName}-${i}' //config.vmssname//'msimage-${vmssName}-${config.name}-${i}'
    userAssignedManagedIdentity: infraGeneric.outputs.UmiResourceId
    extensionsname: 'enablevmAccess' //'VMAccessExtension'
    sshPublicKey: sshKey.outputs.SSHKeyPublicKey
    adminUsername: adminUsername
  }
  dependsOn: [
     vmss[i]
     infraGeneric]
}]



module SharedImageGalleryModule 'imagegallery/main.bicep' = {
  scope: resourceGroup(subscriptionId, 'vmss-${resourceGroupBase}-osimagerg') //vmssgalleryname 
  name: vmssModuleSettings.imagegallery.name
  params: {
    galleryName: galleryName
    location: location
  }
  dependsOn: [osimageresourcegroup]
}

module vmss 'br/CoreModules:az-bm-vm-scalesets:V0.0.2' =  [for (config, i) in vmssConfigs: {
// module vmss 'br/CoreModules:az-bm-vm-scalesets:V0.0.1-preview' =  [for (config, i) in vmssConfigs: {
  name: '${vmssModuleSettings.vmss.name}-${config.name}'
  scope: vmssModuleSettings.vmss.scope
  params: {
    tags: union(mergedTags,{deploymentTimestamp: baseTime}) //tags
    adminUsername: adminUsername
    adminPassword: vmPassword
    imageReference: imageReference //TO DO: Create t-shirt size logic for image name param in OSB
    orchestrationMode: orchestrationMode
    name: '${namingModule.outputs.resourceName}-${i}'//config.vmssname//'msimage-${vmssName}-${config.name}-${i}' //'${namingModule.outputs.baseResourceName}-${i}'
    osDisk: {
      name: 'OSDisk-${config.name}'         
      createOption: osdiskcreateOption
      diskSizeGB: osdiskSizeGB 
      managedDisk: {
        storageAccountType: storageAccountType
        diskEncryptionSet: {
          id: diskset_encryption.outputs.resourceId
         }

      }
    }
    plan: plan
    osType: osType
    dataDisks:[ for i in range(0, datadiskcount): {
              name: 'myDataDisk-${config.name}'
              caching: caching //'ReadOnly'
              createOption: datadiskcreateOption//'Empty'
              diskSizeGB: datadiskSizeGB //'256'
              managedDisk: {
                storageAccountType: 'Premium_LRS'
                diskEncryptionSet: {
                 id: diskset_encryption.outputs.resourceId
               }
              }
            }
    ]
    skuName: skuName
    skuCapacity: config.instanceCount
    availabilityZones: config.zones
    // monitoringWorkspaceId: monitoringWorkspaceId
    bootDiagnosticStorageAccountName: infraGeneric.outputs.name

  publicKeys: !empty(ssh_key) && tierName =='work' ? [
  {
    keyData: sshKey.outputs.SSHKeyPublicKey
    path: '/home/${adminUsername}/.ssh/authorized_keys'
  }
  {
    keyData: ssh_key
    path: '/home/${adminUsername}/.ssh/authorized_keys'
  }
] : [
  {
    keyData: sshKey.outputs.SSHKeyPublicKey
    path: '/home/${adminUsername}/.ssh/authorized_keys'
  }
  {
    keyData: ssh_key
    path: '/home/${adminUsername}/.ssh/authorized_keys'
  }

]

    disablePasswordAuthentication: disablePasswordAuthentication
    location: location 
    nicConfigurations :[
      {
                nicSuffix: 'nic-${i}'
                  ipConfigurations: [
                    {
                      name: 'nic-ip-${i}'
                      properties: {
                         subnet: {
                         id: config.subnetId
                         }
                         loadBalancerBackendAddressPools: [
                          {
                            // id:'${loadBalancerResourceId}/backendAddressPools/${config.backendPoolName}' #vmsstest
                            id:'${loadBalancerResourceId}/backendAddressPools/${namingModule.outputs.resourceName}-${config.backendPoolName}'//'${loadBalancer.outputs.resourceId}/backendAddressPools/${config.backendPoolName}'//string(loadBalancer.outputs.backendpools[0].id)
  
                          }
                        ]
                       }
                     }
                  ]
                  primary: true
                }
            ]
    managedIdentities: {
      userAssignedResourceIds: [infraGeneric.outputs.UmiResourceId]
    }
  }
  dependsOn: [
    diskset_encryption
    vmssKey
    sshKey
    infraGeneric
    loadBalancer
    subnetIPcheck
  ]
 
}
]


module vmssKey 'pre-provisioning/main.bicep' = {

  name: vmssModuleSettings.vmssKey.name
  scope: vmssModuleSettings.vmssKey.scope  
  params: {
    kvName: infraGeneric.outputs.DESKvName
    tenantId: tenantId
    umiPrincipalId: infraGeneric.outputs.UmiPrincipalId
  }
  dependsOn:[infraGeneric]
}

module sshKey '../ssh-pk/main.bicep' = {
  name: vmssModuleSettings.sshKey.name
  scope: vmssModuleSettings.sshKey.scope
  params: {
    location: location
    umiName: umiName
    sshDeploymentScriptName: sshDeploymentScriptName
    sshKeyName: sshPublicKey    
  }
  dependsOn: [ infraGeneric]
}
module dnsrecord  'privatednsrecord/main.bicep' = {
  name: vmssModuleSettings.dnsrecord.name
  scope: vmssModuleSettings.dnsrecord.scope
  params: {
    location: location
    dnsZoneName: dnsZoneName
    ttl: ttl
    // aRecords: aRecords
    aRecords: [
        {
          name: '${namingModule.outputs.resourceName}-0' //'${appName}' // 'authnz360.dev.eastus.7246827ts28100401'
          ips: [lb01PrivateIP]
        }
        {
          name: '${namingModule.outputs.resourceName}-1'//'dev.authnz360'
          ips: [lb02PrivateIP]
        }
      ]
    
    cnameTarget: cnameTarget
    cn_name: cn_name
    // vnetId: vnetId
  }
  dependsOn: [ infraGeneric]
}


module dataCollectionRules '../dcr/main.bicep' = [for (config, i) in vmssConfigs:{ 
  name: '${vmssModuleSettings.dataCollectionRules.name}-${config.name}'
  scope: vmssModuleSettings.dataCollectionRules.scope
  params: {
    associationName: associationName
    // dataCollectionRuleId: dataCollectionRuleId
    vmssName: '${namingModule.outputs.resourceName}-${i}' //config.vmssname//'msimage-${vmssName}-${config.name}-${i}'
    logWorkspaceId: logWorkspaceId
    location: location
    syslogDcrName: syslogDcrName
    dcrRgName: dcrRgName
    dcrSubscriptionId: dcrSubscriptionId
    // syslogDcrName: '${vmssName}-syslogdcr'
    userAssignedManagedIdentity: infraGeneric.outputs.UmiResourceId
  }
  dependsOn: [
    vmss[i]
    infraGeneric
  ]
}]

module osimageresourcegroup 'br/CoreModules:az-bm-resource-group:V0.0.1' = {
    name: vmssModuleSettings.osimageresourcegroup.name
    params: {
      name: 'vmss-${resourceGroupBase}-osimagerg' //'${namingModule.outputs.resourceName}-osimagerg'
      location: location

  }
}

module healthExtensions 'healthcheckextension/main.bicep' = [for (config, i) in healthExtensionConfigs: {
  name: '${vmssModuleSettings.healthExtensions.name}-${i}'
  scope: vmssModuleSettings.healthExtensions.scope
  params: { 
    vmssName: '${namingModule.outputs.resourceName}-${i}' //config.vmssName
    osType: config.osType
    settings: config.settings
  }
  dependsOn: [vmss
    vmssExtensionModule
  ]
}]

module vnetreaderRole 'SubnetIPcheck/vnetreaderrole.bicep' = {
  name: 'vnetRoleAssignment'
  scope: resourceGroup(vnetRG)// Since you're crossing into VNet scope
  params: {
    principalId: infraGeneric.outputs.UmiPrincipalId
    vnetResourceId: vnetId
  }
}
module subnetIPcheck 'SubnetIPcheck/main.bicep' = {
  name: 'subnetIPcheck'
  scope: vmssModuleSettings.vmss.scope
  params: {
    virtualnetwork: virtualnetwork
    subnetname: subnetname
    location: location
    vnetRG : vnetRG 
    UMIId: infraGeneric.outputs.UmiResourceId
    subnetId: privateEndpointSubnetId              
  }
  dependsOn: [ infraGeneric
    vnetreaderRole ]
}

module diskset_encryption 'br/CoreModules:az-bm-disk-encryption-set:V0.0.1' = {
  name: vmssModuleSettings.DES.name
  scope: vmssModuleSettings.DES.scope
  params: { 
    name: '${namingModule.outputs.resourceName}-des'
    location: location
    lock: lock
    keyVaultResourceId: infraGeneric.outputs.DESKvResourceId
    keyName: vmssKey.outputs.cmkName  
    encryptionType: encryptionType
    federatedClientId: federatedClientId
    rotationToLatestKeyVersionEnabled: rotationToLatestKeyVersionEnabled
    managedIdentities: {
      userAssignedResourceIds: [infraGeneric.outputs.UmiResourceId] }
    roleAssignments: roleAssignments
    tags: tags
    enableTelemetry: enableTelemetry
   }
  dependsOn: [
    vmssKey
  ]
}

module LBExistenceCheck 'SubnetIPcheck/LBExistenceCheck.bicep' = {
  name: 'LBExistenceCheck-validation'
  scope: vmssModuleSettings.vmss.scope
  params: {
    subscriptionId:subscriptionId
    location: location
    ResourceGroupName : infraGeneric.outputs.resourceGroupName
    UMIId: infraGeneric.outputs.UmiResourceId
    loadBalancerName: '${namingModule.outputs.resourceName}-persistentlb'//loadBalancerName             
  }
  dependsOn: [ infraGeneric
    vnetreaderRole ]
}


module loadBalancer 'br/public:avm/res/network/load-balancer:0.1.4' =  {
  name: vmssModuleSettings.loadbalancer.name
  scope: vmssModuleSettings.loadbalancer.scope
  params: {

    name: deployLB ? '${namingModule.outputs.resourceName}-persistentlb' : 'skip-lb' //'${namingModule.outputs.resourceName}-persistentlb'
    frontendIPConfigurations: deployLB ?[
  {
    name: '${namingModule.outputs.resourceName}-privipconfigplb01'
    subnetId: privateEndpointSubnetId 
    privateIPAddress: lb01PrivateIP 
    privateIPAllocationMethod: 'Static'
  }
  {
    name: '${namingModule.outputs.resourceName}-privipconfigplb02'
    subnetId: privateEndpointSubnetId 
    privateIPAddress: lb02PrivateIP //DONOT modifty 
  }
]: []
    backendAddressPools: [
      {
        name: '${namingModule.outputs.resourceName}-backendpool01'

      }
      {      
        name: '${namingModule.outputs.resourceName}-backendpool02'

      }
    ]
    loadBalancingRules: [
        {
          backendAddressPoolName: '${namingModule.outputs.resourceName}-backendpool01'
          backendPort: backendPort1 //8080
          disableOutboundSnat: true
          enableFloatingIP: true
          enableTcpReset: false
          // frontendIPConfigurationName: '${vmssName}-privipconfigplb01' #vmsstest
          frontendIPConfigurationName: '${namingModule.outputs.resourceName}-privipconfigplb01'
          frontendPort: frontendPort1 //443
          idleTimeoutInMinutes: idleTimeoutInMinute1 //4
          loadDistribution: 'Default'
          name: 'privateIPLBRule1'
          probeName: 'vmss-probe01'
          protocol: 'Tcp'          
        }

        {
          backendAddressPoolName: '${namingModule.outputs.resourceName}-backendpool02'
          backendPort: backendPort2 //8080
          disableOutboundSnat: true
          enableFloatingIP: true
          enableTcpReset: false
          // frontendIPConfigurationName: '${vmssName}-privipconfigplb02' #vmsstest
          frontendIPConfigurationName: '${namingModule.outputs.resourceName}-privipconfigplb02'
          frontendPort: frontendPort2 //443
          idleTimeoutInMinutes: idleTimeoutInMinute2 //4
          loadDistribution: 'Default'
          name: 'privateIPLBRule2'
          probeName: 'vmss-probe01'
          protocol: 'Tcp'
        }
      ]
    probes: probes
    roleAssignments: [
      {
        principalId: infraGeneric.outputs.UmiPrincipalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'Owner'
      }
      {
        principalId: infraGeneric.outputs.UmiPrincipalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
      }
    ]
    location: location
    skuName: 'Standard'
    tags: tags
  }
  dependsOn: [subnetIPcheck
    LBExistenceCheck
    ]
    
}

module outputKeyVaults 'output/main.bicep' =  {
  name: 'vmssModuleSettings.outputKeyVaults.name' 
  scope: vmssModuleSettings.outputKeyVaults.scope
  params: {
    outputSecretName: osbOutputSecretName
    kvName: osbOutputKeyvault
    // outputSecretName: 'osbOutputSecretName-${i}'
    outputSecretValue: {
      loadBalancerName: loadBalancer.outputs.resourceId//'${namingModule.outputs.resourceName}-persistentlb'
      cname: '${cn_name}.${applicationenvironment}.mastercard.int'
      standby_cname: '${cn_name}.standby.${applicationenvironment}.mastercard.int'
      vmss_blue: '${namingModule.outputs.resourceName}-0'
      vmss_Green: '${namingModule.outputs.resourceName}-1'
      storageAccountName: infraGeneric.outputs.resourceId
      KeyvaultName: infraGeneric.outputs.AppKvName
      MSI: infraGeneric.outputs.UmiName
      VMResourceGroup: infraGeneric.outputs.resourceGroupName
      ImageRG: osimageresourcegroup.outputs.resourceId
      
      }
  }
  dependsOn: [
    dnsrecord
  ]
} 



 
// Deploy Autoscaling modules
module autoscalingModules '../monitor/autoscale/main.bicep' = [for (scale, i) in vmssautoscale: { 
  name: 'vmssModuleSettings.autoscale.name-${i}'
  scope: vmssModuleSettings.autoscale.scope
  // scope: vmssModuleSettings.vmss.scope
  // name: 'autoscale-${scale.name}'
  params: {
    name: '${namingModule.outputs.resourceName}-autoscalesettings-${i}'
    location: location
    vmssResourceId: vmss[i].outputs.resourceId
    minCapacity: scale.min
    maxCapacity: scale.max
    defaultCapacity: scale.default
    cpuIncreaseThreshold: scale.cpuIncrease
    cpuDecreaseThreshold: scale.cpuDecrease
    memoryIncreaseThreshold: scale.memoryIncrease
    memoryDecreaseThreshold: scale.memoryDecrease
  }
  dependsOn: [
    vmss
    vmssExtensionModule
    healthExtensions

  ]
}]

module storageRoleDataReader 'br/CoreModules:az-bm-role-assignment-storage:V0.0.1' = {
  name: 'vmss-vmssModuleSettings.storageRoleDataReader.name'
  scope: vmssModuleSettings.storageRoleDataReader.scope
  params: {
    assignment: {
      principalId: infraGeneric.outputs.UmiPrincipalId
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
      resourceName: infraGeneric.outputs.name
    }
  }
}
module blobstorageContributer 'br/CoreModules:az-bm-role-assignment-storage:V0.0.1' = {
  name: 'blobStorageContributer'
  scope: vmssModuleSettings.storageRoleDataReader.scope
  params: {
    assignment: {
      principalId: infraGeneric.outputs.UmiPrincipalId//'5b0f0ff7-0571-4e2b-9165-325b8319d277'
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
      resourceName: infraGeneric.outputs.name
    }
  }
}

module contributer 'br/CoreModules:az-bm-role-assignment-storage:V0.0.1' = {
  name: 'vmss-vmssModuleSettings.storageRoleDataContributor.name'
  scope: vmssModuleSettings.storageRoleDataContributor.scope
  params: {
    assignment: {
      principalId: infraGeneric.outputs.UmiPrincipalId
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')
      resourceName: infraGeneric.outputs.name
    }
  }
}
module SMBRole 'br/CoreModules:az-bm-role-assignment-storage:V0.0.1' = {
  name:'vmss-vmssModuleSettings.SMBRole.name'
  scope: vmssModuleSettings.SMBRole.scope
  params: {
    assignment: {
      principalId: infraGeneric.outputs.UmiPrincipalId
      roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb')
      resourceName: infraGeneric.outputs.name
    }
  }
}
// =============== //
//   Definitions   //
// =============== //

type managedIdentitiesType = {
  @description('Optional. Enables system assigned managed identity on the resource.')
  systemAssigned: bool?

  @description('Optional. The resource ID(s) to assign to the resource.')
  userAssignedResourceIds: string[]?
}?

type lockType = {
  @description('Optional. Specify the name of lock.')
  name: string?

  @description('Optional. Specify the type of lock.')
  kind: ('CanNotDelete' | 'ReadOnly' | 'None')?
}?

type roleAssignmentType = {
  @description('Required. The role to assign. You can provide either the display name of the role definition, the role definition GUID, or its fully qualified ID in the following format: \'/providers/Microsoft.Authorization/roleDefinitions/c2f4ef07-c644-48eb-af81-4b1b4947fb11\'.')
  roleDefinitionIdOrName: string

  @description('Required. The principal ID of the principal (user/group/identity) to assign the role to.')
  principalId: string

  @description('Optional. The principal type of the assigned principal ID.')
  principalType: ('ServicePrincipal' | 'Group' | 'User' | 'ForeignGroup' | 'Device')?

  @description('Optional. The description of the role assignment.')
  description: string?

  @description('Optional. The conditions on the role assignment. This limits the resources it can be assigned to. e.g.: @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:ContainerName] StringEqualsIgnoreCase "foo_storage_container".')
  condition: string?

  @description('Optional. Version of the condition.')
  conditionVersion: '2.0'?

  @description('Optional. The Resource Id of the delegated managed identity resource.')
  delegatedManagedIdentityResourceId: string?
}[]?

type diagnosticSettingType = {
  @description('Optional. The name of diagnostic setting.')
  name: string?

  @description('Optional. The name of metrics that will be streamed. "allMetrics" includes all possible metrics for the resource. Set to `[]` to disable metric collection.')
  metricCategories: {
    @description('Required. Name of a Diagnostic Metric category for a resource type this setting is applied to. Set to `AllMetrics` to collect all metrics.')
    category: string

    @description('Optional. Enable or disable the category explicitly. Default is `true`.')
    enabled: bool?
  }[]?

  @description('Optional. A string indicating whether the export to Log Analytics should use the default destination type, i.e. AzureDiagnostics, or use a destination type.')
  logAnalyticsDestinationType: ('Dedicated' | 'AzureDiagnostics')?

  @description('Optional. Resource ID of the diagnostic log analytics workspace. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.')
  workspaceResourceId: string?

  @description('Optional. Resource ID of the diagnostic storage account. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.')
  storageAccountResourceId: string?

  @description('Optional. Resource ID of the diagnostic event hub authorization rule for the Event Hubs namespace in which the event hub should be created or streamed to.')
  eventHubAuthorizationRuleResourceId: string?

  @description('Optional. Name of the diagnostic event hub within the namespace to which logs are streamed. Without this, an event hub is created for each log category. For security reasons, it is recommended to set diagnostic settings to send data to either storage account, log analytics workspace or event hub.')
  eventHubName: string?

  @description('Optional. The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic Logs.')
  marketplacePartnerResourceId: string?
}[]?

type customerManagedKeyType = {
  @description('Required. The resource ID of a key vault to reference a customer managed key for encryption from.')
  keyVaultResourceId: string

  @description('Required. The name of the customer managed key to use for encryption.')
  keyName: string

  @description('Optional. The version of the customer managed key to reference for encryption. If not provided, using \'latest\'.')
  keyVersion: string?

  @description('Required. User assigned identity to use when fetching the customer managed key.')
  userAssignedIdentityResourceId: string
}?

type privateEndpointType = {
  @description('Optional. The name of the private endpoint.')
  name: string?

  @description('Optional. The location to deploy the private endpoint to.')
  location: string?

  @description('Optional. The name of the private link connection to create.')
  privateLinkServiceConnectionName: string?

  @description('Optional. The subresource to deploy the private endpoint for. For example "vault", "mysqlServer" or "dataFactory".')
  service: string?

  @description('Required. Resource ID of the subnet where the endpoint needs to be created.')
  subnetResourceId: string

  @description('Optional. The name of the private DNS zone group to create if `privateDnsZoneResourceIds` were provided.')
  privateDnsZoneGroupName: string?

  @description('Optional. The private DNS zone groups to associate the private endpoint with. A DNS zone group can support up to 5 DNS zones.')
  privateDnsZoneResourceIds: string[]?

  @description('Optional. If Manual Private Link Connection is required.')
  isManualConnection: bool?

  @description('Optional. A message passed to the owner of the remote resource with the manual connection request.')
  @maxLength(140)
  manualConnectionRequestMessage: string?

  @description('Optional. Custom DNS configurations.')
  customDnsConfigs: {
    @description('Required. Fqdn that resolves to private endpoint IP address.')
    fqdn: string?

    @description('Required. A list of private IP addresses of the private endpoint.')
    ipAddresses: string[]
  }[]?

  @description('Optional. A list of IP configurations of the private endpoint. This will be used to map to the First Party Service endpoints.')
  ipConfigurations: {
    @description('Required. The name of the resource that is unique within a resource group.')
    name: string

    @description('Required. Properties of private endpoint IP configurations.')
    properties: {
      @description('Required. The ID of a group obtained from the remote resource that this private endpoint should connect to.')
      groupId: string

      @description('Required. The member name of a group obtained from the remote resource that this private endpoint should connect to.')
      memberName: string

      @description('Required. A private IP address obtained from the private endpoint\'s subnet.')
      privateIPAddress: string
    }
  }[]?

  @description('Optional. Application security groups in which the private endpoint IP configuration is included.')
  applicationSecurityGroupResourceIds: string[]?

  @description('Optional. The custom name of the network interface attached to the private endpoint.')
  customNetworkInterfaceName: string?

  @description('Optional. Specify the type of lock.')
  lock: lockType

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType

  @description('Optional. Tags to be applied on all resources/resource groups in this deployment.')
  tags: object?

  @description('Optional. Enable/Disable usage telemetry for module.')
  enableTelemetry: bool?

  @description('Optional. Specify if you want to deploy the Private Endpoint into a different resource group than the main resource.')
  resourceGroupName: string?
}[]?

// ============================ //
// Managed Identity Definitions //
// ============================ //
type federatedIdentityCredentialsType = {
  @description('Required. The name of the federated identity credential.')
  name: string

  @description('Required. The list of audiences that can appear in the issued token.')
  audiences: string[]

  @description('Required. The URL of the issuer to be trusted.')
  issuer: string

  @description('Required. The identifier of the external identity.')
  subject: string
}[]?


// ====================== //
// KeyVaults Definitions  //
// ====================== //
type accessPoliciesType = {
  @description('Optional. The tenant ID that is used for authenticating requests to the key vault.')
  tenantId: string?

  @description('Required. The object ID of a user, service principal or security group in the tenant for the vault.')
  objectId: string

  @description('Optional. Application ID of the client making request on behalf of a principal.')
  applicationId: string?

  @description('Required. Permissions the identity has for keys, secrets and certificates.')
  permissions: {
    @description('Optional. Permissions to keys.')
    keys: (
      | 'all'
      | 'backup'
      | 'create'
      | 'decrypt'
      | 'delete'
      | 'encrypt'
      | 'get'
      | 'getrotationpolicy'
      | 'import'
      | 'list'
      | 'purge'
      | 'recover'
      | 'release'
      | 'restore'
      | 'rotate'
      | 'setrotationpolicy'
      | 'sign'
      | 'unwrapKey'
      | 'update'
      | 'verify'
      | 'wrapKey')[]?

    @description('Optional. Permissions to secrets.')
    secrets: ('all' | 'backup' | 'delete' | 'get' | 'list' | 'purge' | 'recover' | 'restore' | 'set')[]?

    @description('Optional. Permissions to certificates.')
    certificates: (
      | 'all'
      | 'backup'
      | 'create'
      | 'delete'
      | 'deleteissuers'
      | 'get'
      | 'getissuers'
      | 'import'
      | 'list'
      | 'listissuers'
      | 'managecontacts'
      | 'manageissuers'
      | 'purge'
      | 'recover'
      | 'restore'
      | 'setissuers'
      | 'update')[]?

    @description('Optional. Permissions to storage accounts.')
    storage: (
      | 'all'
      | 'backup'
      | 'delete'
      | 'deletesas'
      | 'get'
      | 'getsas'
      | 'list'
      | 'listsas'
      | 'purge'
      | 'recover'
      | 'regeneratekey'
      | 'restore'
      | 'set'
      | 'setsas'
      | 'update')[]?
  }
}[]?

type secretsType = {
  @description('Required. The name of the secret.')
  name: string

  @description('Optional. Resource tags.')
  tags: object?

  @description('Optional. Contains attributes of the secret.')
  attributes: {
    @description('Optional. Defines whether the secret is enabled or disabled.')
    enabled: bool?

    @description('Optional. Defines when the secret will become invalid. Defined in seconds since 1970-01-01T00:00:00Z.')
    exp: int?

    @description('Optional. If set, defines the date from which onwards the secret becomes valid. Defined in seconds since 1970-01-01T00:00:00Z.')
    nbf: int?
  }?
  @description('Optional. The content type of the secret.')
  contentType: string?

  @description('Required. The value of the secret. NOTE: "value" will never be returned from the service, as APIs using this model are is intended for internal use in ARM deployments. Users should use the data-plane REST service for interaction with vault secrets.')
  @secure()
  value: string

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType?
}[]?

type keysType = {
  @description('Required. The name of the key.')
  name: string

  @description('Optional. Resource tags.')
  tags: object?

  @description('Optional. Contains attributes of the key.')
  attributes: {
    @description('Optional. Defines whether the key is enabled or disabled.')
    enabled: bool?

    @description('Optional. Defines when the key will become invalid. Defined in seconds since 1970-01-01T00:00:00Z.')
    exp: int?

    @description('Optional. If set, defines the date from which onwards the key becomes valid. Defined in seconds since 1970-01-01T00:00:00Z.')
    nbf: int?
  }?
  @description('Optional. The elliptic curve name. Only works if "keySize" equals "EC" or "EC-HSM". Default is "P-256".')
  curveName: ('P-256' | 'P-256K' | 'P-384' | 'P-521')?

  @description('Optional. The allowed operations on this key.')
  keyOps: ('decrypt' | 'encrypt' | 'import' | 'release' | 'sign' | 'unwrapKey' | 'verify' | 'wrapKey')[]?

  @description('Optional. The key size in bits. Only works if "keySize" equals "RSA" or "RSA-HSM". Default is "4096".')
  keySize: (2048 | 3072 | 4096)?

  @description('Optional. The type of the key. Default is "EC".')
  kty: ('EC' | 'EC-HSM' | 'RSA' | 'RSA-HSM')?

  @description('Optional. Key release policy.')
  releasePolicy: {
    @description('Optional. Content type and version of key release policy.')
    contentType: string?

    @description('Optional. Blob encoding the policy rules under which the key can be released.')
    data: string?
  }?

  @description('Optional. Key rotation policy.')
  rotationPolicy: rotationPoliciesType?

  @description('Optional. Array of role assignments to create.')
  roleAssignments: roleAssignmentType?
}[]?

type rotationPoliciesType = {
  @description('Optional. The attributes of key rotation policy.')
  attributes: {
    @description('Optional. The expiration time for the new key version. It should be in ISO8601 format. Eg: "P90D", "P1Y".')
    expiryTime: string?
  }?

  @description('Optional. The lifetimeActions for key rotation action.')
  lifetimeActions: {
    @description('Optional. The action of key rotation policy lifetimeAction.')
    action: {
      @description('Optional. The type of action.')
      type: ('Notify' | 'Rotate')?
    }?

    @description('Optional. The trigger of key rotation policy lifetimeAction.')
    trigger: {
      @description('Optional. The time duration after key creation to rotate the key. It only applies to rotate. It will be in ISO 8601 duration format. Eg: "P90D", "P1Y".')
      timeAfterCreate: string?

      @description('Optional. The time duration before key expiring to rotate or notify. It will be in ISO 8601 duration format. Eg: "P90D", "P1Y".')
      timeBeforeExpiry: string?
    }?
  }[]?
}?


// ========= //
//  Outputs  //

@description('The Principal ID of the UMI.')
output umiprincipalId string = infraGeneric.outputs.UmiPrincipalId
// Declare output outside the module block

output loadBalancerResourceId string = deployLB ? loadBalancer.outputs.resourceId : ''
// output loadBalancerResourceId string = loadBalancerExists == false ? loadBalancer.outputs.resourceId : existingLoadBalancer.id
output vmssResourceIdArray array = [for (config, i) in vmssConfigs: '${subscriptionId}/resourceGroups/${persistentRgName}/providers/Microsoft.Compute/virtualMachineScaleSets/${config.name}']
output createdFqdns array = dnsrecord.outputs.fqdnList
// output scriptcontent string = scriptcontent
output sharedimagegallery string = osimageresourcegroup.outputs.resourceId
output imagegalleryName string = osimageresourcegroup.outputs.name
output ResourceGroupName string = infraGeneric.outputs.resourceGroupName
output UMI_ClientID string = infraGeneric.outputs.UmiClientId
// output cn_name string = cn_name






