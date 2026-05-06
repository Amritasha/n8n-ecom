# n8n Ecom Automation Bundle for Railway

Self-host [n8n](https://n8n.io) on Railway with 7 pre-built Shopify automation workflows ready to activate out of the box.

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.app/template/new?template=https://github.com/Amritasha/n8n-ecom)

---

## What's included

| # | Workflow | Trigger | Actions |
|---|----------|---------|---------|
| 1 | 🛍️ New Order Notification | Order paid | Slack message + Google Sheets log |
| 2 | ⚠️ Low Stock Alert | Daily 9am | Checks inventory → Slack if stock ≤ 5 |
| 3 | 🛒 Abandoned Cart Recovery | Checkout created | Waits 1hr → emails if no order placed |
| 4 | ⭐ Review Request | Order fulfilled | Waits 3 days → sends review email |
| 5 | ❌ Failed Payment Alert | Payment failed | Slack alert + customer recovery email |
| 6 | 📊 Weekly Sales Report | Every Monday 8am | Pulls Shopify data → emails dashboard |
| 7 | 👑 VIP Customer Tagging | Order paid | Tags customers with $500+ lifetime spend |

---

## Deploy in 3 steps

### 1. Click Deploy on Railway
Hit the button above. Railway will clone this repo and build the Docker image.

### 2. Set environment variables

These are **already configured** in the image — you don't need to touch them:

| Variable | Pre-set value |
|----------|--------------|
| `N8N_HOST` | `0.0.0.0` |
| `N8N_PROTOCOL` | `https` |
| `N8N_BASIC_AUTH_ACTIVE` | `true` |
| `N8N_PORT` | `$PORT` (Railway's dynamic port) |
| `N8N_PROXY_HOPS` | `1` |
| `N8N_USER_FOLDER` | `/data/n8n` |
| `WEBHOOK_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` (auto-resolves to your Railway domain) |
| `N8N_BASIC_AUTH_USER` | `admin` (override if you want a different username) |
| `GENERIC_TIMEZONE` | `America/New_York` (override for your timezone) |

These are **yours to set** in Railway → Variables:

| Variable | What to put |
|----------|-------------|
| `N8N_ENCRYPTION_KEY` | A random 32-char string — generate with `openssl rand -hex 16` |
| `N8N_BASIC_AUTH_PASSWORD` | Your chosen password |

### 3. Volume for persistence
The template auto-mounts a volume at `/data/n8n`. No manual setup needed — your workflows and credentials persist across deploys.

---

## First login

1. Open your Railway domain in the browser
2. Log in with the `N8N_BASIC_AUTH_USER` / `N8N_BASIC_AUTH_PASSWORD` you set
3. Go to **Workflows** — all 7 workflows are pre-loaded
4. Add your credentials (Shopify, Slack, SendGrid, Google Sheets) under **Credentials**
5. Open each workflow, connect your credentials, and hit **Activate**

---

## Credentials you'll need

- **Shopify** — Admin API key (Settings → Apps → Develop apps)
- **Slack** — Bot token or Incoming Webhook
- **SendGrid** — API key (for transactional emails)
- **Google Sheets** — OAuth2 (for the order log)

---

## Customising workflows

Each workflow is a JSON file in `/workflows`. You can:
- Change the low-stock threshold (default: 5 units) in workflow 02
- Change the VIP spend threshold (default: $500) in workflow 07
- Update `fromEmail` and `YOUR_REVIEW_LINK` placeholders in the email workflows
- Swap SendGrid for Gmail, Mailgun, or any other email node

---

## Stack

- [n8n](https://n8n.io) — workflow automation engine
- [Railway](https://railway.app) — hosting platform
- Docker — containerised deployment

---

## License

MIT
