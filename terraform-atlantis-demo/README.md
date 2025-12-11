# Grafana Cloud + Atlantis + Terraform Demo

GitOps for Grafana dashboards: open a PR, Atlantis runs `terraform plan`, approve and apply, dashboard updates in Grafana Cloud.

## Prerequisites

- Docker & Docker Compose
- Terraform CLI (for local testing)
- ngrok account
- GitHub repo + Personal Access Token
- Grafana Cloud account

## Quick Start

### 1. Create Grafana Cloud Service Account

1. Go to [Grafana Cloud](https://grafana.com) → your stack
2. Navigate to **Administration → Service Accounts**
3. Create account: name=`terraform`, role=`Admin`
4. Add token, copy it (starts with `glsa_`)
5. Note your stack URL (e.g., `https://your-org.grafana.net`)

### 2. Create GitHub PAT token

1. Go to GitHub -> Settings -> Developer Settings -> Personal access tokens -> Tokens (classic)
2. Create a new token with **repo** scope

### 3. Configure Environment

```bash
cp .env.example .env
# Edit .env with your values
```

### 4. Start ngrok

```bash
ngrok http 4141
```

Copy the `https://xxxx.ngrok-free.app` URL into your `.env` as `ATLANTIS_URL`.

### 5. Start Atlantis

```bash
docker compose up -d
```

Check logs: `docker compose logs -f`

### 6. Configure GitHub Webhook

In your repo: **Settings → Webhooks → Add webhook**

- **Payload URL:** `https://your-ngrok-url/events`
- **Content type:** `application/json`
- **Secret:** same as `GITHUB_WEBHOOK_SECRET` in `.env`
- **Events:** Pull requests, Pull request reviews, Issue comments, Pushes

### 7. Demo It!

```bash
# Push to GitHub
git init
git add .
git commit -m "Initial commit"
git remote add origin git@github.com:YOUR_ORG/YOUR_REPO.git
git push -u origin main

# Make a change
git checkout -b update-dashboard
# Edit dashboards/demo.json - change the title or content
git add .
git commit -m "Update dashboard title"
git push -u origin update-dashboard
```

1. Open PR on GitHub
2. Comment with `atlantis plan -p grafana-dashboards` - Atlantis will comment with plan output
3. Comment `atlantis apply` on the PR - Atlantis will apply the change
4. Dashboard updates in Grafana Cloud!

## Creating the Grafana Cloud Token

1. Log into Grafana Cloud
2. Select your stack
3. Go to **Administration → Service Accounts**
4. Click **Add service account**
5. Name: `terraform`, Role: `Admin`
6. Click **Add service account token**
7. Copy the token (starts with `glsa_`)
