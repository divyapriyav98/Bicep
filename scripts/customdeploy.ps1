param (
    [string]$resourceGroup
)

Write-Host "Loading subscription ID from previous step..."
az account set --subscription "$env:SUBSCRIPTION_ID"
Write-Host "Fetching storage account..."
$storageAccount = az storage account list --resource-group $resourceGroup --query "[0].name" -o tsv
$storageAccountId = az storage account list --resource-group $resourceGroup --query "[0].id" -o tsv
az storage account update --name $storageAccount --resource-group $resourceGroup --default-action Deny
if (-not $storageAccount) {
    Write-Host "##vso[task.logissue type=error;]No storage account found in resource group $resourceGroup"
    exit 1
}
Write-Host "Storage Account: $storageAccount"
$identityObjectId = az account show --query "user.identity" -o tsv
Write-Host "Resolving DNS for storage account..."
Write-Host "Fetching containers..."
$containers = az storage container list `
  --account-name $storageAccount `
  --auth-mode key `
  --query "[?starts_with(name, 'vmsscontainer')].name" `
  -o tsv
if (-not $containers) {
    Write-Host "##vso[task.logissue type=error;]No containers found in storage account $storageAccount"
    exit 1
}
az role assignment create --assignee $env:servicePrincipalId --role "Storage Blob Data Contributor" --scope "$storageAccountId"
az role assignment create --assignee $env:servicePrincipalId --role "Owner" --scope "$storageAccountId"
Write-Host "Containers found: $containers"
# Retrieve artifact URLs from environment variable and split them
Start-Sleep -Seconds 30
$artifactUrls = $env:ARTIFACT_URLS -split ","

foreach ($artifactUrl in $artifactUrls) {
    $artifactName = ($artifactUrl -split "/")[-1]  # Extract filename from URL
    Write-Host "Downloading $artifactName from Artifactory..."
    Invoke-WebRequest -Uri "$artifactUrl" -OutFile "$artifactName"

    foreach ($container in $containers) {
        Write-Host "Uploading $artifactName to container: $container"
        az storage blob upload `
          --account-name $storageAccount `
          --container-name $container `
          --file "$artifactName" `
          --name "$artifactName" `
          --auth-mode login
    }
}
$servicebootstrappath = $env:SERVICEBOOTSTRAPNAME
$servicebootstrapname = ($servicebootstrappath -split "/")[-1]
Write-Host "Uploading service-bootstrap.sh to container: $container"
        az storage blob upload `
          --account-name $storageAccount `
          --container-name $container `
          --file "$servicebootstrappath" `
          --name "$servicebootstrapname" `
          --overwrite `
          --auth-mode login

   
Write-Host "Generating files inside container: $container"
az storage blob list --container-name "vmsscontainer" --account-name $storageAccount --auth-mode login --output table

