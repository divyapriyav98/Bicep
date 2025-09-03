param (
    [string]$bicepFile,
    [string]$JSONFile,
    [string]$configPath,
    [string]$configFile,
    [string]$bicepconfigJSONFile

)

Install-Module -Name 'PSRule' -Force
Install-Module -Name 'PSRule.Rules.Azure' -Repository PSGallery -Scope CurrentUser -Force
Install-Module -Name 'Az.Accounts'-Repository PSGallery -Force
Install-Module -Name Az.Resources -Scope CurrentUser -Force -AllowClobber -MinimumVersion 6.7.0 -MaximumVersion 6.9.0
      #         # Uninstall-Module -Name Az.Resources -AllVersions -Force
      #         Install-Module -Name Az.Resources -Scope CurrentUser -Force -AllowClobber -MinimumVersion 6.7.0 -MaximumVersion 6.9.0
      #         Import-Module Az.Resources
      #         Write-Output "Az.Resources Successfully"
      #         Install-Module -Name 'Az.Accounts'-Repository PSGallery -Force
Import-Module PSRule.Rules.Azure
Import-Module PSRule
Import-Module Az.Resources
 
# List available modules (for debugging)
Get-Module -ListAvailable | Where-Object {$_.Name -in 'benchpress.azure', 'pester', 'PSRule', 'PSRule.Rules.Azure', 'Az.Accounts', 'Az.Resources'}
 
$configFile = "$configPath/ps-rule.yaml"
 
# Verify Bicep file exists
if (!(Test-Path $bicepFile)) {
  Write-Output "Bicep file not found: $bicepFile"
  exit 1
} else {
  Write-Output "Bicep file found at: $bicepFile"
}
 # Check Bicep file syntax before validation
Write-Output "Checking Bicep and build to create json from bicep file."
az bicep build --file $bicepFile --outfile $JSONFile 
Write-Output " the json file: $JSONFile"

if ($LASTEXITCODE -ne 0) {
  Write-Output "Bicep file contains syntax errors."
  exit 1
} else {
  Write-Output "Bicep file syntax is valid."
}
 
# Run PSRule validation
Write-Output "Running PSRule validation."
Assert-PSRule -Module 'PSRule.Rules.Azure' -InputPath $JSONFile -Option $configFile -Format File -ErrorAction Continue
 
Write-Output "PSRule validation completed successfully!"
