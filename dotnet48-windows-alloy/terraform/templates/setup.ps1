Write-Host "Starting setup..."

Write-Host "Installing Grafana Alloy..."
Set-Location $env:TEMP
Invoke-WebRequest "https://storage.googleapis.com/cloud-onboarding/alloy/scripts/install-windows.ps1" -OutFile "install-windows.ps1"
& ".\install-windows.ps1" -GCLOUD_RW_API_KEY "${grafana_cloud_cloud_access_policy_token}" -GCLOUD_HOSTED_METRICS_ID "${grafana_cloud_hosted_metrics_id}" -GCLOUD_HOSTED_METRICS_URL "${grafana_cloud_hosted_metrics_url}" -GCLOUD_HOSTED_LOGS_ID "${grafana_cloud_hosted_logs_id}" -GCLOUD_HOSTED_LOGS_URL "${grafana_cloud_hosted_logs_url}" -GCLOUD_FM_URL "${grafana_cloud_fm_url}" -GCLOUD_FM_POLL_FREQUENCY "60s" -GCLOUD_FM_HOSTED_ID "${grafana_cloud_fm_hosted_id}"

Write-Host "Appending Windows metrics and logs configuration to Alloy..."
$alloyConfigPath = "C:\Program Files\GrafanaLabs\Alloy\config.alloy"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$windowsScrapeConfig = Get-Content "$scriptDir\windows_scrape.alloy" -Raw
Add-Content -Path $alloyConfigPath -Value "`n$windowsScrapeConfig"

Write-Host "Restarting Alloy service..."
Restart-Service -Name "Alloy" -Force

Write-Host "Installing IIS and ASP.NET 4.8..."
Install-WindowsFeature -Name Web-Server -IncludeManagementTools
Install-WindowsFeature -Name Web-Asp-Net45

Write-Host "Downloading cheese-app from GitHub Release..."
$appZipUrl = "https://github.com/monodot/dotnet-playground/releases/download/${cheese_app_release_tag}/cheese-app-build.zip"
$appZip = "$env:TEMP\cheese-app-build.zip"
$appPath = "C:\inetpub\wwwroot\cheeseapp"

Invoke-WebRequest -Uri $appZipUrl -OutFile $appZip -UseBasicParsing

Write-Host "Deploying application..."
New-Item -ItemType Directory -Path $appPath -Force
Expand-Archive -Path $appZip -DestinationPath $appPath -Force

Write-Host "Configuring IIS..."
Import-Module WebAdministration
Remove-Website -Name "Default Web Site" -ErrorAction SilentlyContinue
New-Website -Name "CheeseApp" -Port 80 -PhysicalPath $appPath -ApplicationPool "DefaultAppPool"

$module_url = "https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/latest/download/OpenTelemetry.DotNet.Auto.psm1"
$download_path = Join-Path $env:temp "OpenTelemetry.DotNet.Auto.psm1"
Invoke-WebRequest -Uri $module_url -OutFile $download_path -UseBasicParsing

Import-Module $download_path
Install-OpenTelemetryCore
Register-OpenTelemetryForIIS

Write-Host "Setup complete!"
