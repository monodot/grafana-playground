Write-Host "Starting setup..."

Write-Host "Installing Grafana Alloy..."
Set-Location $env:TEMP
Invoke-WebRequest "https://storage.googleapis.com/cloud-onboarding/alloy/scripts/install-windows.ps1" -OutFile "install-windows.ps1"
& ".\install-windows.ps1" -GCLOUD_RW_API_KEY "${grafana_cloud_cloud_access_policy_token}" -GCLOUD_HOSTED_METRICS_ID "${grafana_cloud_hosted_metrics_id}" -GCLOUD_HOSTED_METRICS_URL "${grafana_cloud_hosted_metrics_url}" -GCLOUD_HOSTED_LOGS_ID "${grafana_cloud_hosted_logs_id}" -GCLOUD_HOSTED_LOGS_URL "${grafana_cloud_hosted_logs_url}" -GCLOUD_FM_URL "${grafana_cloud_fm_url}" -GCLOUD_FM_POLL_FREQUENCY "60s" -GCLOUD_FM_HOSTED_ID "${grafana_cloud_fm_hosted_id}"

Write-Host "Deploying application..."
# Add your app deployment commands here

Write-Host "Setup complete!"
