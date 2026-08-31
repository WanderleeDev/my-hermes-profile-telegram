# Cloudflare API Workflow

Quick reference for listing Cloudflare resources via API.

## Setup

Ensure `CLOUDFLARE_API_TOKEN` is set in `~/.hermes/profiles/telegram-bot/.env`

```bash
# From .env
CLOUDFLARE_API_TOKEN=cfut_...
```

## Get Account ID

```bash
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/accounts" | \
  python3 -c "import sys,json; d=json.load(sys.stdin); [print(f\"{a['id']} | {a['name']}\") for a in d.get('result',[])]"
```

## List Pages Projects

```bash
ACCOUNT_ID="your-account-id"
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/pages/projects" | \
  python3 -c "
import sys, json
d = json.load(sys.stdin)
if d.get('success'):
    for p in d.get('result', []):
        print(f\"{p.get('name', 'N/A')} | {p.get('subdomain', 'N/A')} | {p.get('framework', 'N/A')}\")
"
```

## List Workers Scripts

```bash
ACCOUNT_ID="your-account-id"
curl -s -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/workers/scripts" | \
  python3 -c "
import sys, json
d = json.load(sys.stdin)
if d.get('success'):
    for s in d.get('result', []):
        print(f\"{s.get('id', 'N/A')} | {s.get('name', 'N/A')} | {s.get('created_on', 'N/A')}\")
"
```

## Key Notes

- Token format: `cfut_...` (modern) or legacy keys
- Rate limit: ~1000 req/min on free tier
- All endpoints require `Authorization: Bearer <token>` header
- Account ID is different from Zone ID
- Pages projects include subdomain, framework, latest deployment info
