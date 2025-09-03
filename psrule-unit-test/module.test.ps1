Describe 'Postgres Unit test - Deploy Bicep File and Test' {

    BeforeAll {
        param (
            [string]$randomString = -join ((65..90) + (97..122) | get-random -Count 8 | ForEach-Object {[char]$_})
        )
        $script:RandomString = $RandomString
        $script:resourceGroupName = "abt-rg-unit-test-$randomString"
        $script:location = "eastus"
        $script:bicepFilePath = "./unit-test.bicep"
        $script:resourceType = "PostgreSqlFlexibleServer"

        $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
        if (-not $resourceGroup) {
            Write-Host "Creating Resource Group: $resourceGroupName" -ForegroundColor green
            New-AzResourceGroup -Name $resourceGroupName -Location $location
        } else {
            Write-Host "Resource Group $resourceGroupName already exists." -ForegroundColor green
        }

        Write-Host "Deploying $resourceType using Bicep file: $bicepFilePath" -ForegroundColor green
        $deploymentResult = New-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -TemplateFile $bicepFilePath -ErrorAction Stop

        if ($deploymentResult.ProvisioningState -ne 'Succeeded') {
            throw "Bicep deployment failed. Provisioning State: $($deploymentResult.ProvisioningState)"
        }
        else {
            $deploymentOutput = Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name "generateResourceName"
            $script:appName = $deploymentOutput.outputs.resourceName.value
        }   
     }

    It "Should have successfully deployed the $resourceType or verified it exists" {
        Write-Host "Checking if $resourceType $appName deployed.." -ForegroundColor green
        $server = Get-AzPostgreSqlFlexibleServer -ResourceGroupName $resourceGroupName -ServerName $appName -ErrorAction SilentlyContinue

        $server | Should -Not -BeNullOrEmpty
    }
}

AfterAll {
    Write-Host "Removing Resource: $resourceGroupName and $appName " -ForegroundColor green
    Remove-AzResourceGroup -Name $resourceGroupName -Force -ErrorAction SilentlyContinue
}
