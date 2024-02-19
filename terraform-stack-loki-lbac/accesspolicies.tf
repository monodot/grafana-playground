data "grafana_cloud_organization" "current" {
  provider = grafana.cloud
  slug     = "tomdonohue" // Obviously replace this with your own organisation :) 
}

resource "grafana_cloud_access_policy" "test" {
  provider     = grafana.cloud
  region       = "us"
  name         = "lokilbacdemo-dev-only-policy"
  display_name = "lokilbacdemo dev-only policy"

  scopes = ["logs:read"]

  realm {
    type       = "org"
    identifier = data.grafana_cloud_organization.current.id

    label_policy {
      selector = "{environment=\"development\"}"
    }
    label_policy {
      selector = "{team=\"developers\"}"
    }
  }
}

resource "grafana_cloud_access_policy_token" "test" {
  provider         = grafana.cloud
  region           = "us"
  access_policy_id = grafana_cloud_access_policy.test.policy_id
  name             = "lokilbacdemo-dev-only-token"
  display_name     = "lokilbacdemo dev-only Token"
}
