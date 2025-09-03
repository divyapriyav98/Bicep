param(
    [string]$subscriptionId,
    [string]$resourceGroup,
    [string]$umiclientid
)
az account set --subscription $subscriptionId
Write-Output "Fetching VMSS from resource group: $resourceGroup"
$vmssNames = az vmss list --resource-group $resourceGroup --query "[].name" -o tsv
$storageAccount = az storage account list --resource-group $resourceGroup --query "[0].name" -o tsv
$containers = az storage container list --account-name "$storageAccount" --auth-mode login --query "[?starts_with(name, 'vmsscontainer')].name" -o tsv
az storage account update --name $storageAccount --resource-group $resourceGroup --default-action Deny
foreach ($vmss in $vmssNames) {
az vmss update --resource-group $resourceGroup --name  $vmss --set tags.VMSSCreatedOn=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
$tagvalue = az vmss show --resource-group "$resourceGroup" --name "$vmss" --query 'tags.VMSSCreatedOn' -o tsv
Write-Output "VMSS timestammp: $tagvalue"
}

# Allow public read access on the container
az storage container set-permission `
  --name $containers `
  --account-name $storageAccount `
  --public-access blob

Write-Output "VMSS Names: $vmssNames"
Write-Output "Storage Account: $storageAccount"
Write-Output "Containers: $containers"
$SCRIPT_BLOB_NAME = "simple-healthcheck-server-start-script-0.0.6"
$SIGNED_SCRIPT_URL = "https://$storageAccount.blob.core.windows.net/$containers/$SCRIPT_BLOB_NAME"
# $SIGNED_SCRIPT_URL = "https://$storageAccount.blob.core.windows.net/$containers/$SCRIPT_BLOB_NAME?$SAS_TOKEN"
Write-Output "Final Signed URL: $SIGNED_SCRIPT_URL"

Write-Output "list of custom extension"
az vm extension image list --location "eastus" --query "[?publisher=='Microsoft.Azure.Extensions' && contains(name, 'CustomScriptExtension')]"
# $settings = @"
# {
#   "fileUris": ["$SIGNED_SCRIPT_URL"],
#   "commandToExecute": "chmod +x simple-healthcheck-server-start-script-0.0.6 && ./simple-healthcheck-server-start-script-0.0.6"
# }
# "@
#####################################
$BOOTSTRAP_BLOB_NAME = "service-bootstrap.sh"
$SIGNED_BOOTSTRAP_URL = "https://$storageAccount.blob.core.windows.net/$containers/$BOOTSTRAP_BLOB_NAME"
$settings = @"
{
  "fileUris": [
    "$SIGNED_BOOTSTRAP_URL",
    "$SIGNED_SCRIPT_URL"
  ],
  "commandToExecute": "chmod +x service-bootstrap.sh simple-healthcheck-server-start-script-0.0.6 && ./service-bootstrap.sh && ./simple-healthcheck-server-start-script-0.0.6"
}
"@
$protectedSettings = @{
  managedIdentity = @{
    clientId = "$umiclientid"
  }
}
$protectedSettingsJson = $protectedSettings | ConvertTo-Json -Depth 3



foreach ($vmss in $vmssNames) {
    Write-Output "Processing VMSS: $vmss"
$subnetId = az vmss show `
--resource-group $resourceGroup `
--name $vmss `
--query "virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id" `
-o tsv

Write-Output "Allowing subnet access to storage account using ID: $subnetId"

# Add the subnet to the storage account network rules
az storage account network-rule add `
--resource-group $resourceGroup `
--account-name $storageAccount `
--subnet $subnetId
Write-Output "custom script on vmss level "

    az vmss extension set --resource-group $resourceGroup --vmss-name $vmss --name "CustomScript" --publisher "Microsoft.Azure.Extensions" --version "2.1" --settings $settings --protected-settings $protectedSettingsJson
    Write-Output "custom script on vm level "
    $vmssResourceId = az vmss show --resource-group $resourceGroup --name $vmss --query "id" -o tsv
    Write-Output "auto scaling on vmss" 
    # Start-Sleep -Seconds 30
    # az vmss scale --resource-group $resourceGroup --name $vmss --new-capacity 3  
    $autoscaleSettings = az monitor autoscale list --resource-group $resourceGroup `
    --query "[?contains(targetResourceUri, '$vmssResourceId')]" -o json | ConvertFrom-Json
 
    if ($autoscaleSettings.Count -gt 0) {
      $existingSettingName = $autoscaleSettings[0].name
      Write-Output "Autoscale already exists for ${vmss}: ${existingSettingName}"
 
      az monitor autoscale update --resource $vmssResourceId --resource-group $resourceGroup --min-count 2 --max-count 10 --count 2 --name $existingSettingName --enabled true
    } else {
      $autoscaleName = "$vmss-Autoscale"
      Write-Output "Creating autoscale for ${vmss}: ${autoscaleName}"
 
      az monitor autoscale create --resource $vmssResourceId --resource-group $resourceGroup --min-count 2 --max-count 10 --count 2 --name $autoscaleName --enabled true
      ### FORCE SCALE HERE ###
      Write-Output "Setting initial capacity to 2 instances for VMSS: $vmss"
      az vmss scale --resource-group $resourceGroup --name $vmss --new-capacity 2
      ###FORCE SCALE HERE ###
    # Write-Output "Setting initial capacity to 2 instances for VMSS: $vmss"
    # az vmss scale --resource-group $resourceGroup --name $vmss --new-capacity 3
      Write-Output "Autoscaling applied to VMSS: $vmss"
      
    }
    Write-Output "Disabling public access to storage account and container..."

# Remove public access from the container
az storage account update --name $storageAccount --resource-group $resourceGroup --default-action Deny
}
Write-Output "Custom Script Extension applied to VMSS & Flexible VM instances successfully!"

