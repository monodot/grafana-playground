resource "aws_ssm_parameter" "alloy_config" {
  name  = "/alloy-daemon/${var.environment_id}/config"
  type  = "String"
  tier  = "Advanced"
  value = <<-EOT
logging {
  level  = "info"
  format = "logfmt"
}

otelcol.receiver.otlp "default" {
  grpc {
    endpoint = "0.0.0.0:4317"
  }

  http {
    endpoint = "0.0.0.0:4318"
  }

	output {
		metrics = [otelcol.processor.resourcedetection.default.input]
		logs    = [otelcol.processor.resourcedetection.default.input]
		traces  = [otelcol.processor.resourcedetection.default.input]
	}
}

otelcol.processor.resourcedetection "default" {
	detectors = ["env", "system", "ecs"] // add "gcp", "ec2", "ecs", "elastic_beanstalk", "eks", "lambda", "azure", "aks", "consul", "heroku"  if you want to use cloud resource detection

	system {
		hostname_sources = ["os"]
	}

	output {
		metrics = [otelcol.processor.transform.drop_unneeded_resource_attributes.input]
		logs    = [otelcol.processor.transform.drop_unneeded_resource_attributes.input]
		traces  = [otelcol.processor.transform.drop_unneeded_resource_attributes.input]
	}
}

otelcol.processor.transform "drop_unneeded_resource_attributes" {
	// https://grafana.com/docs/alloy/latest/reference/components/otelcol.processor.transform/
	error_mode = "ignore"

	trace_statements {
		context    = "resource"
		statements = [
			"delete_key(attributes, \"k8s.pod.start_time\")",
			"delete_key(attributes, \"os.description\")",
			"delete_key(attributes, \"os.type\")",
			"delete_key(attributes, \"process.command_args\")",
			"delete_key(attributes, \"process.executable.path\")",
			"delete_key(attributes, \"process.pid\")",
			"delete_key(attributes, \"process.runtime.description\")",
			"delete_key(attributes, \"process.runtime.name\")",
			"delete_key(attributes, \"process.runtime.version\")",
		]
	}

	metric_statements {
		context    = "resource"
		statements = [
			"delete_key(attributes, \"k8s.pod.start_time\")",
			"delete_key(attributes, \"os.description\")",
			"delete_key(attributes, \"os.type\")",
			"delete_key(attributes, \"process.command_args\")",
			"delete_key(attributes, \"process.executable.path\")",
			"delete_key(attributes, \"process.pid\")",
			"delete_key(attributes, \"process.runtime.description\")",
			"delete_key(attributes, \"process.runtime.name\")",
			"delete_key(attributes, \"process.runtime.version\")",
		]
	}

	log_statements {
		context    = "resource"
		statements = [
			"delete_key(attributes, \"k8s.pod.start_time\")",
			"delete_key(attributes, \"os.description\")",
			"delete_key(attributes, \"os.type\")",
			"delete_key(attributes, \"process.command_args\")",
			"delete_key(attributes, \"process.executable.path\")",
			"delete_key(attributes, \"process.pid\")",
			"delete_key(attributes, \"process.runtime.description\")",
			"delete_key(attributes, \"process.runtime.name\")",
			"delete_key(attributes, \"process.runtime.version\")",
		]
	}

	output {
		metrics = [otelcol.processor.transform.add_resource_attributes_as_metric_attributes.input]
		logs    = [otelcol.processor.batch.default.input]
		traces  = [
			otelcol.processor.batch.default.input,
			otelcol.connector.host_info.default.input,
		]
	}
}

otelcol.connector.host_info "default" {
	host_identifiers = ["host.name"]

	output {
		metrics = [otelcol.processor.batch.default.input]
	}
}

otelcol.processor.transform "add_resource_attributes_as_metric_attributes" {
	error_mode = "ignore"

	metric_statements {
		context    = "datapoint"
		statements = [
			"set(attributes[\"deployment.environment\"], resource.attributes[\"deployment.environment\"])",
			"set(attributes[\"service.version\"], resource.attributes[\"service.version\"])",
		]
	}

	output {
		metrics = [otelcol.processor.batch.default.input]
	}
}

otelcol.processor.batch "default" {
	output {
		metrics = [otelcol.exporter.otlphttp.grafana_cloud.input]
		logs    = [otelcol.exporter.otlphttp.grafana_cloud.input]
		traces  = [otelcol.exporter.otlphttp.grafana_cloud.input]
	}
}

otelcol.auth.basic "grafana_cloud" {
  username = env("GRAFANA_CLOUD_INSTANCE_ID")
  password = env("GRAFANA_CLOUD_API_KEY")
}

otelcol.exporter.otlphttp "grafana_cloud" {
  client {
    endpoint = env("GRAFANA_CLOUD_OTLP_ENDPOINT")
    auth     = otelcol.auth.basic.grafana_cloud.handler
  }
}
EOT

  tags = {
    Name = "alloy-daemon-config-${var.environment_id}"
  }
}