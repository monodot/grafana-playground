---
keywords: ["Grafana", "automation"]
---

# Git Sync demo

Demonstrates the Git Sync feature in Grafana 12.

## Prerequisites

Generate a Personal Access Token in GitHub:

- Type = fine-grained
- Select a repository
- Then, add these permissions for Git Sync:
  - Contents: Read and write permission
  - Metadata: Read-only permission
  - Pull requests: Read and write permission
  - Webhooks: Read and write permission

## Steps

Go to Grafana on http://localhost:3012

1.  Navigate to **Administration -> General -> Provisioning**

2.  Enter your personal access token, repository URL, branch (`main`) and directory (this one is `grafana-git-sync-demo/dashboards`).

3.  Click through to create the configuration.

4.  Watch the dashboards in this folder sync to your Grafana instance.

5.  Create a new dashboard in this folder, save it, and it will be committed to this Git repo.
