<#
.SYNOPSIS
    Triggers an HCP Terraform run purely via the REST API -- no VCS, no
    local terraform CLI. Demonstrates the API-driven workflow pattern used
    by custom CI integrations (Jenkins, internal tooling, etc.) that don't
    use HCP Terraform's native VCS integration.

.PARAMETER WorkspaceId
    The target workspace ID (e.g. "ws-QVnbJSD7sEAtsZe9").

.PARAMETER ConfigDir
    Local directory containing the .tf files to upload.

.PARAMETER Token
    HCP Terraform API token. Defaults to reading from the same credentials
    file `terraform login` writes to, if not supplied.

.PARAMETER Message
    Run message shown in the HCP Terraform UI.

.PARAMETER Destroy
    If set, triggers a destroy run instead of an apply.

.EXAMPLE
    ./trigger-api-run.ps1 -WorkspaceId "ws-QVnbJSD7sEAtsZe9" -ConfigDir "." -Message "Deploy via pipeline"

.EXAMPLE
    ./trigger-api-run.ps1 -WorkspaceId "ws-QVnbJSD7sEAtsZe9" -ConfigDir "." -Destroy -Message "Teardown demo"
#>

param(
    [Parameter(Mandatory = $true)][string]$WorkspaceId,
    [Parameter(Mandatory = $true)][string]$ConfigDir,
    [string]$Token,
    [string]$Message = "Triggered via API",
    [switch]$Destroy
)

if (-not $Token) {
    $credsPath = "$env:APPDATA\terraform.d\credentials.tfrc.json"
    if (-not (Test-Path $credsPath)) {
        throw "No token supplied and no credentials file found at $credsPath. Run 'terraform login' first, or pass -Token explicitly."
    }
    $creds = Get-Content $credsPath | ConvertFrom-Json
    $Token = $creds.credentials."app.terraform.io".token
}

$headers = @{ Authorization = "Bearer $Token"; "Content-Type" = "application/vnd.api+json" }
$baseUrl = "https://app.terraform.io/api/v2"

function New-ConfigVersion {
    $body = @{
        data = @{
            type       = "configuration-versions"
            attributes = @{ "auto-queue-runs" = $false }
        }
    } | ConvertTo-Json -Depth 5

    Invoke-RestMethod -Method Post -Uri "$baseUrl/workspaces/$WorkspaceId/configuration-versions" -Headers $headers -Body $body
}

function Send-ConfigUpload($UploadUrl, $Directory) {
    $archive = Join-Path $env:TEMP "tfconfig-$(Get-Random).tar.gz"
    $tfFiles = Get-ChildItem -Path $Directory -Filter "*.tf" | Select-Object -ExpandProperty Name

    if ($tfFiles.Count -eq 0) {
        throw "No .tf files found in $Directory"
    }

    Push-Location $Directory
    try {
        tar -czf $archive $tfFiles
        Invoke-RestMethod -Method Put -Uri $UploadUrl -InFile $archive -ContentType "application/octet-stream"
    }
    finally {
        Pop-Location
        Remove-Item $archive -ErrorAction SilentlyContinue
    }
}

function New-Run($ConfigVersionId, $RunMessage, $IsDestroy) {
    $attributes = @{ message = $RunMessage }
    if ($IsDestroy) {
        $attributes["is-destroy"] = $true
    }

    $body = @{
        data = @{
            type          = "runs"
            attributes    = $attributes
            relationships = @{
                workspace               = @{ data = @{ type = "workspaces"; id = $WorkspaceId } }
                "configuration-version" = @{ data = @{ type = "configuration-versions"; id = $ConfigVersionId } }
            }
        }
    } | ConvertTo-Json -Depth 6

    Invoke-RestMethod -Method Post -Uri "$baseUrl/runs" -Headers $headers -Body $body
}

Write-Host "Creating configuration version..."
$cv = New-ConfigVersion
Write-Host "  Config version: $($cv.data.id)"

Write-Host "Uploading configuration from $ConfigDir..."
Send-ConfigUpload -UploadUrl $cv.data.attributes."upload-url" -Directory $ConfigDir

Write-Host "Triggering $(if ($Destroy) { 'destroy' } else { 'apply' }) run..."
$run = New-Run -ConfigVersionId $cv.data.id -RunMessage $Message -IsDestroy $Destroy.IsPresent
Write-Host "  Run created: $($run.data.id)"
Write-Host "  View at: https://app.terraform.io/app/gcpcloudhub/workspaces/-/runs/$($run.data.id)"

return $run.data.id
