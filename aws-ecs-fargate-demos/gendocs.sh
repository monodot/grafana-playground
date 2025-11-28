#!/bin/sh

podman run --rm --volume "$(pwd):/terraform-docs:z" -u root quay.io/terraform-docs/terraform-docs:0.18.0 markdown --output-file /terraform-docs/README.md /terraform-docs

