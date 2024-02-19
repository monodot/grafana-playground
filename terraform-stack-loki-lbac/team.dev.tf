resource "grafana_team" "dev_team" {
  provider = grafana.stack
  name     = "Development Team"
  email    = "development.team@example.com"
  members  = []
}

resource "grafana_data_source" "loki_for_devs" {
  provider            = grafana.stack
  type                = "loki"
  name                = "loki-for-developers"
  uid                 = "loki-for-developers"
  url                 = grafana_cloud_stack.demo.logs_url
  basic_auth_enabled  = true
  basic_auth_username = grafana_cloud_stack.demo.logs_user_id

  json_data_encoded = jsonencode({})

  secure_json_data_encoded = jsonencode({
    basicAuthPassword = grafana_cloud_access_policy_token.test.token
  })
}

resource "grafana_data_source_permission" "loki_for_devs" {
  provider      = grafana.stack
  datasource_id = grafana_data_source.loki_for_devs.id
  permissions {
    built_in_role = "Admin"
    permission    = "Admin"
  }
  permissions {
    team_id    = grafana_team.dev_team.id
    permission = "Query"
  }
}