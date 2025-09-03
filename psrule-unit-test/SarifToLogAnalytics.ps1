param(
    [string]$workspaceId,
    [string]$workspaceKey,
    [string]$sarifFolderPath
)
# Function to calculate HMAC-SHA256
function Get-HmacHash {
    param (
        [string]$key,
        [string]$message
    )
    $keyBytes = [System.Text.Encoding]::UTF8.GetBytes($key)
    $messageBytes = [System.Text.Encoding]::UTF8.GetBytes($message)
    $hmacsha256 = New-Object System.Security.Cryptography.HMACSHA256
    $hmacsha256.Key = $keyBytes
    $hashBytes = $hmacsha256.ComputeHash($messageBytes)
    return [BitConverter]::ToString($hashBytes) -replace '-'
}
 
# Define the SARIF folder path
# $sarifFolderPath = "$(Build.ArtifactStagingDirectory)/sarif-output/sarif-output-reports"  # Path to the SARIF artifact folder
$logType = "PSRuleResults"  # Custom log type for SARIF results
 
# Find all SARIF files in the artifact folder
$sarifFiles = Get-ChildItem -Path $sarifFolderPath -Filter *.sarif -Recurse
 
# Debugging: Print the number of SARIF files found
Write-Host "SARIF files found: $($sarifFiles.Count)"
# If no files are found, exit early
if ($sarifFiles.Count -eq 0) {
    Write-Host "No SARIF files found in the folder $sarifFolderPath"
    exit 1
}
 
# Debugging: Print paths of all found SARIF files
Write-Host "SARIF Files to process: $($sarifFiles | ForEach-Object { $_.FullName })"
 
# Initialize flag for successful log sending
$allLogsSent = $true
 

 
# Loop over each SARIF file
foreach ($sarifFile in $sarifFiles) {
    Write-Host "Sending SARIF data to Log Analytics for $($sarifFile.Name)"  # Debugging log to confirm iteration
 
    # Read the SARIF file content
    try {
        $sarifContent = Get-Content -Path $sarifFile.FullName -Raw
        Write-Host "SARIF content read successfully from $($sarifFile.Name)"
    } catch {
        Write-Host "Failed to read SARIF file: $($sarifFile.Name), Error: $_"
        $allLogsSent = $false  # Mark flag as false if there's an issue reading the file
        continue
    }
 
    # Prepare the HTTP request to Log Analytics Data Collector API
    $date = (Get-Date).ToString("R")
    $uri = "https://$workspaceId.ods.opinsights.azure.com/api/logs?api-version=2016-04-01"
    # Construct the string to sign in one line
    # $stringToSign = "POST`n$($sarifContent.Length)`napplication/json`n$date`n/api/logs"
 
    # # Ensure correct construction of the string to sign
    # $stringToSign = "POST" + "`n" +
    # "$($sarifContent.Length)" + "`n" +  # Body length
    # "application/json" + "`n" +         # Content-Type
    # "$date" + "`n" +                    # Date header
    # "/api/logs"                          # Request URI path
    Write-Host "the string to sign is: $stringToSign"                
 
    # Compute the signature using HMAC-SHA256
    $signature = Get-HmacHash -key ${workspaceKey} -message $stringToSign
     Write-Host "the signature is: $signature"
 
    # Build the Authorization header with SharedKey and the computed signature
    $headers = @{
        "Authorization" = "SharedKey ${workspaceId}:${signature}"
        "Content-Type"  = "application/json"
        "x-ms-date"     = $date  # Add x-ms-date header
    }
    # Debugging: Log headers
    Write-Host "Authorization Header: $($headers['Authorization'])"
    Write-Host "x-ms-date Header: $($headers['x-ms-date'])"  
    # Prepare the body of the request
    $body = @{
        "logType" = $logType
        "records" = @(
            @{
                "SarifResult" = $sarifContent  # Send the SARIF content as a custom field
            }
        )
    } | ConvertTo-Json -Depth 3
 
    # Send the HTTP request to Log Analytics
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ContentType "application/json"
        Write-Host "Successfully sent SARIF data to Log Analytics for $($sarifFile.Name)"
    } catch {
        Write-Host "Failed to send SARIF data to Log Analytics for $($sarifFile.Name): $_"
        $allLogsSent = $false  # Mark flag as false if there's an issue sending the log
    }
}
 
# After all iterations, check if all logs were sent successfully
if ($allLogsSent -eq $false) {
    Write-Host "Some SARIF logs failed to send. Exiting with error."
    exit 1  # Fail the pipeline if any log failed to send
}
 
Write-Host "All SARIF logs were successfully sent to Log Analytics."
