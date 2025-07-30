locals {
  config_bucket_name = "${var.service_namespace}-config-${var.environment_id}"
}

resource "aws_s3_bucket" "config" {
  bucket = local.config_bucket_name
}

resource "aws_s3_bucket_versioning" "config" {
  bucket = aws_s3_bucket.config.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "alloy_sidecar_config" {
  bucket = aws_s3_bucket.config.id
  key    = "config_sidecar.alloy"
  source = "${path.module}/templates/config_sidecar.alloy"
  etag   = filemd5("${path.module}/templates/config_sidecar.alloy")
}

resource "aws_s3_object" "alloy_initcontainer_script" {
  bucket = aws_s3_bucket.config.id
  key    = "init_alloy_config.sh"
  source = "${path.module}/templates/init_alloy_config.sh"
  etag   = filemd5("${path.module}/templates/init_alloy_config.sh")
}

resource "aws_cloudwatch_log_group" "alloy_sidecar" {
  name = "${var.service_namespace}-alloy-sidecar-${var.environment_id}"
}

data "aws_iam_policy_document" "task" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.config.arn}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:DescribeServices",
      "ecs:ListTagsForResource"
    ]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "s3_access" {
  name        = "${var.service_namespace}-alloy-s3-access-${var.environment_id}"
  description = "Policy for ECS task to access app config S3 bucket"
  policy      = data.aws_iam_policy_document.task.json
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.s3_access.arn
}



resource "aws_ecs_task_definition" "alloy_sidecar" {
  family                   = "${var.service_namespace}-alloy-sidecar-task-def-${var.environment_id}"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task_execution.arn # Add task role for S3 access
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  volume {
    name = "alloy-config"
  }

  volume {
    name = "app-code"
  }

  container_definitions = jsonencode([
    # Container that writes JS code into a volume, saves us from having to build and push an image to ECR
    # TODO: Convert this into a command that copies the code from a temporary S3 bucket (it's cleaner)
    {
      name      = "app-code-writer"
      essential = false
      image     = "busybox:latest"
      memory    = 256
      command = [
        "sh", "-c",
        <<-EOT
    echo "Writing /app/package.json"
    cat > /app/package.json << 'EOF'
    ${file("${path.module}/trace-generator/package.json")}
    EOF

    echo "Writing /app/index.js"
    cat > /app/index.js << 'EOF'
    ${file("${path.module}/trace-generator/index.js")}
    EOF

    echo "Writing /app/loadtest.js"
    cat > /app/loadtest.js << 'EOF'
    ${file("${path.module}/trace-generator/loadtest.js")}
    EOF

    echo "Done."
    EOT
      ]
      mountPoints = [
        {
          sourceVolume  = "app-code"
          containerPath = "/app"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.alloy_sidecar.name
          "awslogs-region"        = data.aws_region.current.id
          "awslogs-stream-prefix" = "app-code-writer"
        }
      }
    },

    # Our main app container, uses the code which was written to the volume by app-code-writer
    # In a real implementation, you would deploy your app here.
    {
      name             = "sample-app"
      image            = "docker.io/library/node:18-alpine"
      essential        = true
      workingDirectory = "/app"
      mountPoints = [
        {
          sourceVolume  = "app-code"
          containerPath = "/app"
        }
      ]
      command = [
        "sh", "-c",
        "npm install --silent && node --require @opentelemetry/auto-instrumentations-node/register index.js"
      ]
      dependsOn = [
        {
          containerName = "alloy-sidecar",
          condition     = "HEALTHY"
        }
      ]
      environment = [
        {
          name  = "OTEL_EXPORTER_OTLP_ENDPOINT"
          value = "http://localhost:4318" # HTTP endpoint for Alloy
        },
        # You could add additional resource attributes here, instead of using AWS tags
        # This is the easiest way to add 'tags' (i.e. attributes) to telemetry signals
        {
          name  = "OTEL_RESOURCE_ATTRIBUTES"
          value = "service.name=${var.service_name_alloy_sidecar},service.namespace=${var.service_namespace},deployment.environment=production"
        },
        # {
        #   name = "OTEL_LOG_LEVEL"
        #   value = "debug"
        # }
      ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.alloy_sidecar.name,
          "awslogs-region"        = data.aws_region.current.id,
          "awslogs-stream-prefix" = "sample-app"
        }
      },
    },

    # Init container that copies a generic Alloy configuration from S3
    {
      name       = "config-writer",
      essential  = false,
      image      = "amazon/aws-cli:latest",
      memory     = 256,
      entryPoint = ["/bin/sh"],
      command = [
        "-c",
        <<-EOT
aws s3 cp s3://${local.config_bucket_name}/config_sidecar.alloy /etc/alloy/config.alloy

aws s3 cp s3://${local.config_bucket_name}/init_alloy_config.sh ./init_alloy_config.sh
chmod u+x ./init_alloy_config.sh

./init_alloy_config.sh
    EOT
      ],
      environment = [
        {
          name  = "AWS_DEFAULT_REGION"
          value = data.aws_region.current.id
        },
        {
          name  = "ECS_CLUSTER_NAME"
          value = aws_ecs_cluster.main.name
        },
        {
          name  = "ECS_SERVICE_NAME"
          value = var.service_name_alloy_sidecar
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.alloy_sidecar.name,
          "awslogs-region"        = data.aws_region.current.id,
          "awslogs-stream-prefix" = "config-writer"
        }
      },
      mountPoints = [
        {
          sourceVolume  = "alloy-config",
          containerPath = "/etc/alloy"
        }
      ]
    },

    # Run Alloy as a sidecar container so we can shape/transform telemetry locally
    {
      name      = "alloy-sidecar"
      image     = "docker.io/grafana/alloy:latest"
      essential = true

      # Wait for the config-writer container to finish before starting Alloy
      dependsOn = [
        {
          containerName = "config-writer",
          condition     = "COMPLETE"
        }
      ]
      healthCheck = {
        command = [
          "CMD-SHELL",
          "bash -c 'exec 3<>/dev/tcp/localhost/12345 && printf \"GET /-/ready HTTP/1.1\\r\\nHost: localhost\\r\\nConnection: close\\r\\n\\r\\n\" >&3 && read response <&3 && echo $response | grep \"200 OK\" || exit 1'"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 10
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.alloy_sidecar.name
          "awslogs-region"        = data.aws_region.current.id,
          "awslogs-stream-prefix" = "alloy"
        }
      }

      environment = [
        {
          name  = "GRAFANA_CLOUD_OTLP_ENDPOINT",
          value = var.grafana_cloud_otlp_endpoint
        },
        {
          name  = "GRAFANA_CLOUD_INSTANCE_ID",
          value = var.grafana_cloud_instance_id
        },
        {
          name  = "GRAFANA_CLOUD_API_KEY",
          value = var.grafana_cloud_access_policy_token
        },
        {
          name  = "LOKI_ENDPOINT",
          value = var.loki_endpoint_with_auth
        },
        {
          name  = "PROMETHEUS_REMOTE_WRITE_URL"
          value = var.prometheus_remote_write_url
        },
        {
          name  = "PROMETHEUS_USERNAME"
          value = var.prometheus_username
        },
        {
          name  = "PROMETHEUS_PASSWORD"
          value = var.grafana_cloud_access_policy_token
        },
        # An example of a custom resource attribute which is applied to telemetry by Alloy
        {
          name  = "CUSTOM_DEPARTMENT"
          value = "sales"
        },
        {
          name  = "CUSTOM_OWNER"
          value = "salesteam@example.com"
        }
      ],

      mountPoints = [
        {
          sourceVolume  = "alloy-config",
          containerPath = "/etc/alloy"
        }
      ]
    },

    # Scrape container mem/CPU metrics directly and forward to Alloy
    {
      name      = "ecs-exporter"
      image     = "quay.io/prometheuscommunity/ecs-exporter:latest"
      essential = false
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.alloy_sidecar.name,
          "awslogs-region"        = data.aws_region.current.id,
          "awslogs-stream-prefix" = "ecs-exporter"
        }
      },

    },

    # A k6 container to load-test the app for demonstration purposes
    {
      name             = "k6"
      image            = "docker.io/grafana/k6:latest"
      workingDirectory = "/app"
      command = [
        "run",
        "/app/loadtest.js"
      ]
      environment = [
        {
          name  = "API_URL"
          value = "http://localhost:3000" # Endpoint to test
        },
      ],
      restartPolicy = {
        enabled = true
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.alloy_sidecar.name
          "awslogs-region"        = data.aws_region.current.id,
          "awslogs-stream-prefix" = "k6"
        }
      }
      # TODO: Implement me
      # dependsOn = [
      #   {
      #     containerName = "sample-app",
      #     condition     = "HEALTHY"
      #   }
      # ]
      mountPoints = [
        {
          sourceVolume  = "app-code"
          containerPath = "/app"
        }
      ]
    }

  ])
}

resource "aws_ecs_service" "alloy_sidecar" {
  name            = var.service_name_alloy_sidecar
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.alloy_sidecar.arn
  desired_count   = 2 # Simulate multiple instances of this app
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnet.default.id]
    security_groups  = [data.aws_security_group.default.id]
    assign_public_ip = true
  }

  # These tags will be fetched and then attached to the application's telemetry by Alloy
  tags = {
    Name        = var.service_name_alloy_sidecar
    Environment = var.environment_id
    Namespace   = var.service_namespace
  }

}
