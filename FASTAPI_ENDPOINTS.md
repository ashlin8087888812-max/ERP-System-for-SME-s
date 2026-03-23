# FastAPI SaaS - URL Endpoints Called

## XML-RPC URLs (FastAPI → Odoo)

**Base Path:** `{ODOO_HOST}` (from `.env` — see [Environment Config](#environment-config) below)

| Path | File:Line | Why Used |
|------|-----------|----------|
| `/xmlrpc/2/common` | `client.py:21-25` | Authenticate service user, get UID |
| `/xmlrpc/2/object` | `client.py:61-65` | All data operations (execute_kw) |

---

## REST URLs Exposed (FastAPI ← Flutter)

**Base Path:** `/api/v1`

| Path | Method | File:Line | Why Used |
|------|--------|-----------|----------|
| `/` | GET | `main.py:127` | Root health check |
| `/metrics` | GET | `main.py:137` | Prometheus metrics |
| `/health` | GET | `health.py:78` | Full health check |
| `/health/live` | GET | `health.py:106` | Kubernetes liveness probe |
| `/health/ready` | GET | `health.py:112` | Kubernetes readiness probe |
| `/api/v1/auth/signup` | POST | `auth.py:121` | Register new user |
| `/api/v1/auth/login` | POST | `auth.py:161` | User login |
| `/api/v1/auth/refresh` | POST | `auth.py:179` | Refresh access token |
| `/api/v1/auth/logout` | POST | `auth.py:273` | Logout current session |
| `/api/v1/auth/logout-all` | POST | `auth.py:337` | Logout all devices |
| `/api/v1/users/` | GET | `users.py:11` | List users |
| `/api/v1/users/me` | GET | `users.py:28` | Get current user |
| `/api/v1/users/{user_id}` | GET | `users.py:37` | Get user by ID |
| `/api/v1/users/{user_id}` | PUT | `users.py:62` | Update user |
| `/api/v1/users/{user_id}` | DELETE | `users.py:113` | Delete user |
| `/api/v1/admin/users` | GET | `admin.py:10` | Admin list all users |
| `/api/v1/admin/metrics/discuss` | GET | `discuss_metrics.py:9` | Discuss metrics |
| `/api/v1/contacts/count` | GET | `contacts.py:220` | Count contacts |
| `/api/v1/contacts/` | GET | `contacts.py:287` | List contacts |
| `/api/v1/contacts/{contact_id}` | GET | `contacts.py:375` | Get contact details |
| `/api/v1/contacts/` | POST | `contacts.py:413` | Create contact |
| `/api/v1/contacts/{contact_id}` | PUT | `contacts.py:491` | Update contact |
| `/api/v1/contacts/{contact_id}` | DELETE | `contacts.py:571` | Delete contact |
| `/api/v1/discuss/channels` | GET | `discuss.py:20` | List channels |
| `/api/v1/discuss/channels/{channel_id}/messages` | GET | `discuss.py:31` | Get channel messages |
| `/api/v1/discuss/channels/{channel_id}/messages` | POST | `discuss.py:80` | Post message |
| `/api/v1/discuss/channels/{channel_id}/seen` | POST | `discuss.py:101` | Mark as seen |
| `/api/v1/discuss/inbox` | GET | `discuss.py:47` | Get inbox messages |
| `/api/v1/discuss/starred` | GET | `discuss.py:58` | Get starred messages |
| `/api/v1/discuss/history` | GET | `discuss.py:69` | Get message history |
| `/api/v1/attachments/{attachment_id}` | GET | `attachments.py:14` | Download attachment |
| `/api/v1/attachments/upload` | POST | `attachments.py:82` | Upload attachment |
| `/api/v1/scm/purchase-orders` | POST | `scm.py:32` | Create purchase order |
| `/api/v1/scm/grn` | POST | `scm.py:77` | Create goods receipt |
| `/api/v1/ws` | WS | `ws.py:14` | General WebSocket |
| `/api/v1/ws/discuss` | WS | `discuss_ws.py:65` | Discuss WebSocket |

---

## Environment Config

**File:** `fastapi_saas/.env` → loaded by `app/config.py` (`Settings` class)

| Variable | Example | Used By |
|----------|---------|--------|
| `ODOO_HOST` | `http://localhost:8069` | Global Odoo instance URL — used by `crud.create_company()`, tenant middleware, `promote_user.py`, `create_test_user.py` |
| `ODOO_SERVICE_USER` | `123@456` | XML-RPC auth in `client.py` |
| `ODOO_SERVICE_PASSWORD` | `admin` | XML-RPC auth in `client.py` |

> **Note:** `odoo_host` was removed from the `/api/v1/auth/signup` request body. Companies now default to the global `ODOO_HOST` from `.env`. The per-company `odoo_host` DB column is kept for future multi-instance support.