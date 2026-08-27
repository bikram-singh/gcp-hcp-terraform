locals {
  # Strip the "https://" scheme -- monitored_resource wants a bare hostname.
  cloud_run_host = replace(var.cloud_run_url, "https://", "")
}

resource "google_monitoring_uptime_check_config" "cloud_run_uptime" {
  project      = var.project_id
  display_name = "gcphub-${var.environment}-cloud-run-uptime"
  timeout      = "10s"
  period       = var.check_interval_seconds

  http_check {
    path         = "/"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      host = local.cloud_run_host
    }
  }
}

resource "google_monitoring_notification_channel" "email" {
  project      = var.project_id
  display_name = "gcphub-${var.environment}-uptime-alerts"
  type         = "email"

  labels = {
    email_address = var.notification_email
  }
}

resource "google_monitoring_alert_policy" "uptime_alert" {
  project      = var.project_id
  display_name = "gcphub-${var.environment}-cloud-run-uptime-alert"
  combiner     = "OR"

  conditions {
    display_name = "Uptime check failed"

    condition_threshold {
      filter          = "resource.type=\"uptime_url\" AND metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" AND metric.label.check_id=\"${google_monitoring_uptime_check_config.cloud_run_uptime.uptime_check_id}\""
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "60s"

      aggregations {
        alignment_period     = "1200s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.host", "resource.label.project_id"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  alert_strategy {
    auto_close = "1800s"
  }
}
