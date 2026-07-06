# bccashierauditlog

Backend service for syncing audit logs from `dedecashier` and `dedestaff2` into PostgreSQL, then answering Telegram questions with AI using the synced audit rows.

## Flow

```text
dedecashier/dedestaff2 -> POST /api/audit/sync -> PostgreSQL
Telegram question -> webhook/polling -> AI analyzer -> query audit_logs -> Telegram reply
```

## Setup

```bash
cp .env.example .env
docker compose up -d postgres
npm install
npm run migrate
npm run dev
```

Default PostgreSQL connection:

```text
host: localhost
port: 5432
database: bccashier_audit_log
```

## API

### POST `/api/audit/sync`

Headers:

```text
Authorization: Bearer <AUDIT_API_KEY>
```

Body:

```json
{
  "shopId": "demo-shop",
  "sourceApp": "cashier",
  "deviceId": "cashier-main",
  "logs": [
    {
      "eventType": "TABLE_OPENED",
      "timestamp": 1779951361000,
      "tableId": 32,
      "command": "staff.open_table",
      "traceId": "abc",
      "requestBody": {},
      "responseBody": {},
      "details": {}
    }
  ]
}
```

### GET `/api/audit/search`

Query params:

```text
shopId=demo-shop&tableId=32&sourceApp=cashier&from=2026-05-28T00:00:00+07:00&to=2026-05-29T00:00:00+07:00&limit=500
```

### GET `/api/audit/table-timeline`

Returns a table-focused replay with normalized events, deterministic bug signals, and session state.

```text
shopId=demo-shop&tableId=32&from=2026-05-28T00:00:00+07:00&to=2026-05-29T00:00:00+07:00&limit=2000
```

Useful state fields:

```text
state.finalBeforeFirstReopenRowId
state.firstReopenAfterFinalCloseRowId
state.reopenAfterFinalCloseRowIds
state.latestFinalizedRowId
```

### GET `/api/audit/bug-signals`

Runs the deterministic detector without OpenAI.

```text
shopId=demo-shop&tableId=32&from=2026-05-28T00:00:00+07:00&to=2026-05-29T00:00:00+07:00&limit=2000
```

### GET `/api/audit/logic-knowledge`

Returns the business logic and source-code logic knowledge that the AI analyzer uses.

### POST `/api/ai/analyze`

Body:

```json
{
  "shopId": "demo-shop",
  "question": "โต๊ะ 32 วันที่ 28/05/2026 บิลหายเกิดจากอะไร",
  "tableId": 32,
  "from": "2026-05-28T00:00:00+07:00",
  "to": "2026-05-29T00:00:00+07:00"
}
```

## Telegram

Telegram can be wired with webhook later:

```text
POST /api/telegram/webhook/:secret
```

Allowed chats are controlled by `TELEGRAM_ALLOWED_CHAT_IDS`.

## Cloudflare Tunnel For Local Testing

Run the service with Docker:

```bash
docker compose up -d app
```

Health check:

```bash
curl http://localhost:8088/health
```

The Docker service connects to PostgreSQL on the Windows host with:

```text
DATABASE_URL from local .env
```

If you want to run without Docker:

```bash
npm.cmd run dev
```

For a named Cloudflare Tunnel, put the connector token in `.env`:

```env
CLOUDFLARED_TOKEN=<token from Cloudflare Zero Trust>
```

In Cloudflare Zero Trust, configure the public hostname for tunnel `bccashieraudit` to route to:

```text
http://app:8088
```

Then expose Docker service with Cloudflare Tunnel:

```bash
docker compose --profile tunnel up cloudflared
```

Copy the generated `https://*.trycloudflare.com` URL from the Docker logs.

Use it from cashier/staff:

```text
POST http://AUDIT_SERVICE_HOST:8088/api/audit/sync
```

Or through Cloudflare Tunnel:

```text
POST https://<your-tunnel>.trycloudflare.com/api/audit/sync
```

Telegram webhook URL:

```text
https://<your-tunnel>.trycloudflare.com/api/telegram/webhook/<TELEGRAM_WEBHOOK_SECRET>
```
