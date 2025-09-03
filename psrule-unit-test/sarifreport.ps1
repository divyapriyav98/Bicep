param (
    [string]$InputPath,
    [string]$OutputPath
)
 
# Check if the input file exists
if (-not (Test-Path -Path $InputPath)) {
    Write-Host "Error: Input file not found at $InputPath"
    exit
}

# BEFORE PROCESSING - Ensure the output directory exists
$directory = Split-Path -Path $OutputPath
if (-not (Test-Path -Path $directory)) {
    Write-Host "Creating SARIF output directory: $directory"
    New-Item -ItemType Directory -Force -Path $directory
}
 
# Read the file content
$content = Get-Content -Path $InputPath
Write-Host "sarifoutput path:"

 
# Skip header and parse results
$results = $content | Where-Object { $_ -notmatch "^(RuleName|----)" } | ForEach-Object {
    $columns = $_ -split '\s{2,}'
    if ($columns.Count -ge 4 -and $columns[1] -match '^\d+$') {
        [PSCustomObject]@{
            RuleName = $columns[0]
            Pass     = [int]$columns[1]
            Fail     = [int]$columns[2]
            Outcome  = $columns[3]
        }
    }
}
 
if ($results.Count -eq 0) {
    Write-Host "No valid results found in the input file."
    exit
}
 
$formattedResults = $results | ForEach-Object {
    [PSCustomObject]@{
        ruleId = $_.RuleName
        level  = if ($_.Outcome -eq "Pass") { "note" } else { "error" }
        message = @{
            text = "Outcome: $($_.Outcome) (Pass: $($_.Pass), Fail: $($_.Fail))"
        }
    }
}
 
$sarifOutput = @{
    version = "2.1.0"
    runs = @(
        @{
            tool = @{
                driver = @{
                    name = "PSRule"
                    version = "1.0.0"
                    informationUri = "https://psrule.dev"
                }
            }
            results = $formattedResults
        }
    )
}
 
# Ensure output directory exists
$directory = Split-Path -Path $OutputPath
if (-not (Test-Path -Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force
}
 
$sarifOutput | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "SARIF output generated successfully at: $OutputPath"
 
# Display SARIF content
Get-Content $OutputPath | Out-String
