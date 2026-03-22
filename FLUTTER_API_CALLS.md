# Flutter Frontend - URL Endpoints Called

## HTTP Endpoints

**Base Path:** `{BASE_URL}` (default: `http://localhost:8000/api/v1`)

| Path | Method | File:Line | Why Used |
|------|--------|-----------|----------|
| `/auth/login` | POST | `auth_repository.dart:14` | User login |
| `/auth/refresh` | POST | `api_client.dart:130` | Token refresh on 401 |
| `/contacts/` | GET | `contacts_repository.dart:23` | List contacts |
| `/contacts/{id}` | GET | `contacts_repository.dart:47` | Get contact details |
| `/contacts` | POST | `contacts_repository.dart:53` | Create contact |
| `/contacts/{id}` | PUT | `contacts_repository.dart:65` | Update contact |
| `/contacts/{id}` | DELETE | `contacts_repository.dart:74` | Delete contact |
| `/discuss/channels` | GET | `threads_repository.dart:17` | List channels |
| `/discuss/channels/{id}/messages` | GET | `threads_repository.dart:23` | Get channel messages |
| `/discuss/channels/{id}/messages` | POST | `threads_repository.dart:69` | Post message |
| `/discuss/inbox` | GET | `threads_repository.dart:61` | Get inbox messages |
| `/discuss/starred` | GET | `threads_repository.dart:62` | Get starred messages |
| `/discuss/history` | GET | `threads_repository.dart:63` | Get message history |

---

## WebSocket Endpoints

**Base Path:** `{WS_URL}` or derived from `BASE_URL`

| Path | File:Line | Why Used |
|------|-----------|----------|
| `/api/v1/ws` | `websocket_service.dart:62` | Real-time updates (contacts, etc.) |
| `/api/v1/ws/discuss` | `discuss_ws_service.dart:40` | Real-time chat messages |

**Query Parameters:**
- `token` - JWT auth token (required)
- `company_id` - Company ID (required for discuss)
- `channel_ids` - Comma-separated channel IDs (required for discuss)