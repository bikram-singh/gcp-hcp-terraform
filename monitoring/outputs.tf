output "uptime_check_id" {
  value = google_monitoring_uptime_check_config.cloud_run_uptime.uptime_check_id
}

output "alert_policy_name" {
  value = google_monitoring_alert_policy.uptime_alert.display_name
}
