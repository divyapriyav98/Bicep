<#
.SYNOPSIS
    This script processes an OSB (Oracle Service Bus) manifest and performs various operations based on the manifest data.
 
.DESCRIPTION
    The script takes an OSB manifest as input and performs the following tasks:
    1. Converts the OSB manifest payload to a PowerShell object.
    2. Extracts relevant information from the manifest, such as the resource type, subscription ID, key vault URL, environment, app name, and location.
    3. Converts the T-shirt size specified in the manifest to Bicep parameters.
    4. Updates the Bicep parameters file with the requested resource and configurations.
    5. Publishes provisioning global variables to the pipeline environment.
    6. Processes the OSB Bicep values and updates the payload parameters and override values.
    7. Publishes the updated Bicep parameters file.
 
.PARAMETER osbManifest
    The OSB manifest in JSON format.
 
.EXAMPLE
    ProcessOSBManifest.ps1 -osbManifest '{"serviceSpecification": {...}}'
 
.NOTES
    This script requires PowerShell version 5.1 or later.
#>
 
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$osbManifest,
    [Parameter(Mandatory = $true)]
    [string]$osbOutputSecretName
)
 
 
function GetTShirtJsonL {
    param(
        [string]$resourceType,
        [string]$size
    )
 
 
    $jsonFilePath = "azure-resources/$resourceType/resourceSizes.json"
    $jsonContent = Get-Content -Path $jsonFilePath -Raw | ConvertFrom-Json -AsHashtable
    Write-Host "Resource Type to be provisioned: $($resourceType)"
    $forSize = $jsonContent[$size]
    if ($null -eq $forSize) {
        Write-Host "Resource Type to be provisioned: $($resourceType)"
        Write-Host "Size requested: $($size)"
        Write-Host "Size not found in resourceSizes.json"
 
        return $null
    }
    else {
        $forSize.GetEnumerator() | ForEach-Object {
            Write-Host "Adding Key: $($_.Key) Value: $($_.Value)"
            $bicepParamsData.Add($_.Key, $_.Value)  | Out-Null
        }
    }
    return $forSize
}
Function Publish-PipelineVariables {
    param (
        [Parameter(Mandatory = $true)]
        [string]$provisioningVariable,
        [Parameter(Mandatory = $true)]
        [string]$provisioningVariableValue
    )
    Write-Host ("Publishing variable [{0}] with value [{1}] to pipeline environment" -f $provisioningVariable, $provisioningVariableValue)
    Write-Host ("##vso[task.setvariable variable={0}]{1}" -f "$($provisioningVariable);issecret=false;isOutput=true", $provisioningVariableValue)
}
Write-Host "Pipeline ID and RunID to store output to KeyVault: $osbOutputSecretName"
$bicepParamsData = @{}
try {
    # Process OSB Manifest payload as PowerShell Object
    $osbManifestObject = $osbManifest | ConvertFrom-Json
    Write-Host "OSB Manifest Object: "
    $osbManifestObject
    $serviceSpecification = $osbManifestObject
 
    $bicepParamsData.Add("osbOutputSecretName", $osbOutputSecretName) | Out-Null
 
    # Get Service resource Type and split from resource type version if present
    $resourceType = ($serviceSpecification.type -split '@')[0]
    Write-Host "Resource Type to be provisioned: $($resourceType)"
 
    # Get SubscriptionId
    $subscriptionId = $serviceSpecification.provisioningTarget.subscriptionId
    $bicepParamsData.Add("subscriptionId", $subscriptionId) | Out-Null
    Write-Host "SubscriptionId from OSB: $($subscriptionId)"
 
    # Get OSB output Keyvault URl, RG and KV's subscription ID
    $keyVaultUrl = New-Object System.uri($serviceSpecification.osb.keyVaultUrl)
    Write-Host "OSB output keyVaultUrl: $($keyVaultUrl)"
    $osbkv = $keyVaultUrl.Host.Split('.')[0]
    Write-Host "OSB output KeyVault Name Trimed: $($osbkv)"
 
    $bicepParamsData.Add("osbOutputKeyvault", $osbkv) | Out-Null
 
    $osbOutputKeyvaultSubscriptionId = $serviceSpecification.osb.subscriptionId
    $bicepParamsData.Add("osbOutputKeyvaultSubscriptionId", $osbOutputKeyvaultSubscriptionId) | Out-Null
    Write-Host "OSB output KeyvaultSubscriptionId: $($osbOutputKeyvaultSubscriptionId)"
 
    $osbOutputKeyvaultRgName = $serviceSpecification.osb.resourceGroup
    $bicepParamsData.Add("osbOutputKeyvaultRgName", $osbOutputKeyvaultRgName) | Out-Null
    Write-Host "OSB output KeyvaultRgName: $($osbOutputKeyvaultRgName)"
 
    # Get Bicep Parameters and extract environment and AppName
    $bicepparameters = $serviceSpecification.parameters
    Write-Host "BicepParam from OSB servicespecification:"
    $bicepparameters
    $environment = $bicepparameters.environment
    $appName = $bicepparameters.appName
    $location = $bicepparameters.location

    ######################## added ##############################
    $tiername = $bicepparameters.tiername
    $shortTierName = $bicepparameters.shortTierName
    $shortEnvironmentName = $bicepparameters.shortEnvironmentName

    #################################################################



    # Update bicep parameters file with requested resource and configurations.
    $bicepparameters.PSObject.Properties | ForEach-Object {
        $bicepParamKey = $_.Name
        $bicepParamValue = $_.Value
        # Convert TShirt Size to Bicep Parameters
        if ($bicepParamKey -eq "size") {
            GetTShirtJsonL -resourceType $resourceType -size $bicepParamValue
        }
        else {
            $bicepParamsData.Add($bicepParamKey, $bicepParamValue) | Out-Null
        }
    }
    # Get Metadata and convert to bicep tags
    $tags = $serviceSpecification.metadata  
    $bicepParamsData.Add("tags", $tags) | Out-Null
 
    $osbParametersDirectory = "params/$($resourceType)"
    $osbBicpParamFile = "{0}/{1}-{2}" -f $osbParametersDirectory, $appName, "osb.bicepparam.json"
    $bicepParamsData | ConvertTo-Json -depth 100 | Set-Content -Path  $osbBicpParamFile -Force

   ##################### added#######################
       # Get additional variables from metadata
    $hostingEnvironment = $tags.hostingEnvironment.ToLower()
    $applicationEnvironment = $tags.applicationEnvironment.ToLower()
    $size = $bicepparameters.size
   
    #Publish provisoning global variables to pipeline environment
    Publish-PipelineVariables -provisioningVariable 'subscriptionId' -provisioningVariableValue $subscriptionId
    Publish-PipelineVariables -provisioningVariable 'az_resource_name' -provisioningVariableValue $resourceType
    Publish-PipelineVariables -provisioningVariable 'environment' -provisioningVariableValue $environment.ToLower()
    Publish-PipelineVariables -provisioningVariable 'appName' -provisioningVariableValue $appName.ToLower()
    Publish-PipelineVariables -provisioningVariable 'location' -provisioningVariableValue $location.ToLower()
    Publish-PipelineVariables -provisioningVariable 'tiername' -provisioningVariableValue $tiername.ToLower()
    Publish-PipelineVariables -provisioningVariable 'size' -provisioningVariableValue $size
    Publish-PipelineVariables -provisioningVariable 'hostingEnvironment' -provisioningVariableValue $hostingEnvironment.ToLower()
    Publish-PipelineVariables -provisioningVariable 'applicationEnvironment' -provisioningVariableValue $applicationEnvironment.ToLower()
    Publish-PipelineVariables -provisioningVariable 'shortTierName' -provisioningVariableValue $shortTierName.ToLower()
    Publish-PipelineVariables -provisioningVariable 'shortEnvironmentName' -provisioningVariableValue $shortEnvironmentName.ToLower()


  #################################commented below ########################################
 
    # # Publish provisoning global variables to pipeline environment
    # Publish-PipelineVariables -provisioningVariable 'subscriptionId' -provisioningVariableValue $subscriptionId
    # Publish-PipelineVariables -provisioningVariable 'az_resource_name' -provisioningVariableValue $resourceType
    # Publish-PipelineVariables -provisioningVariable 'environment' -provisioningVariableValue $environment
    # Publish-PipelineVariables -provisioningVariable 'appName' -provisioningVariableValue $appName
    # Publish-PipelineVariables -provisioningVariable 'location' -provisioningVariableValue $location



    # Publishing Processed OSB Bicep Values
    $overrideParameters = Get-Content -Path $osbBicpParamFile -Raw | ConvertFrom-Json
    $mainBicepParm = Get-Content -path "params/$($resourceType)/main.bicepparam"
    # Updating payload parameters values and override values from OSB
    $overrideParameters.psobject.Properties | ForEach-Object {
        $key = $_.Name
        $value = $_.value
        $overrideBicepParameter = "param $($key) = " 
        $bicepParameter = "\bparam $($key)\b"
 
        # Inject and reformat tags
        if ($key -eq "tags") {
            $bicepTags = $value | ConvertTo-Json -Depth 100 -Compress
            $overrideBicepParameter += $bicepTags.Replace('"', '''')
        }
        elseif ($value -is [Int64] -or $value -is [Int32] ) {
            $overrideBicepParameter += $value
        }
        else {
            $overrideBicepParameter += "'$value'"
        }
        # Inject OSB payload parameters into parameters file
        $mainBicepParm = $mainBicepParm | ForEach-Object {
            if ($_ | Select-String -Pattern $bicepParameter -Quiet) {
                $overrideBicepParameter
            }
            else {
                $_
            }
        }
    }
 
    # Publishing updated bicep parameters file 
    Set-Content -Path "params/$($resourceType)/main.bicepparam" -Value $mainBicepParm -Force
    Get-Content -path "params/$($resourceType)/main.bicepparam"
}
catch {
    Write-Host "Exception occurred while deserializing the OSB Manifest"
    $osbManifest
    Write-Error "Error: $($_.Exception.Message)"
    Write-Error "StackTrace: $($_.Exception.StackTrace)"
    exit 1
}
