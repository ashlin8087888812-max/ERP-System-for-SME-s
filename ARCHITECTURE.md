# Gestace Architecture Overview

Gestace is a full-stack SaaS ecosystem comprising two major components: a Python **FastAPI backend** (`fastapi_saas`) and a Dart **Flutter frontend** (`flutter_frontend`). The backend connects to an underlying **Odoo** instance via XML-RPC for ERP functionality, heavily leveraging PostgreSQL for its own data layer, and Redis for Celery task queuing and WebSocket Pub/Sub. The frontend is a cross-platform mobile/web client communicating with the FastAPI backend via REST APIs and WebSockets.

---

## 1. High-Level Architecture

```mermaid
graph TD;
    A[Flutter Frontend Client] -->|REST (HTTP) / WebSocket| B(FastAPI Backend)
    B -->|XML-RPC| C[Odoo Instance]
    B -->|SQLAlchemy| D[(PostgreSQL)]
    B -->|Pub/Sub & Broker| E[(Redis)]
    B -->|Celery Workers| F[Async Task Queue]
    F -->|XML-RPC| C
    F -->|SQLAlchemy| D
```

### Key Technologies
- **Backend:** Python 3.11+, FastAPI, SQLAlchemy (ORM), Alembic, Celery, Redis, Uvicorn.
- **Frontend:** Flutter, Dart, Riverpod (State Management), GoRouter (Navigation), Dio (HTTP Client).
- **Integrations:** Odoo XML-RPC, Prometheus/Grafana (Logging & Metrics).

---

## 2. FastAPI Backend (`fastapi_saas`) File-by-File Breakdown

The backend is built around FastAPI and follows a modular application layout.

### `app/` Directory (Core Application Logic)
This is where the entire backend structure is located.

- **`main.py`**: The application entry point. It sets up the FastAPI app instance, configures CORS, hooks in global middlewares (observability, database logging, tenant management), and mounts all API routers.
- **`config.py`**: Pydantic `BaseSettings` that load from `.env`. Contains environment secrets and connection strings (Database, Redis, Odoo XML-RPC credentials).

#### `app/api/v1/` (REST & WebSocket Routes)
Contains all application endpoints. Each file here mounts routes for a specific business domain.
- **`auth.py`**: Endpoints for signup, login, refresh tokens, and logout.
- **`deps.py`**: Dependency injections used across route handlers (e.g., extracting the `current_user` from JWT).
- **`contacts.py`**: CRUD operations for contacts querying data from Odoo and the local DB.
- **`discuss.py` / `discuss_ws.py`**: Endpoints and WebSocket handlers for the real-time chat functionality.
- **`scm.py`**: Supply Chain Management operations like generating Purchase Orders or Goods Receipts.
- **`ws.py`**: General WebSocket endpoints for broadcasting generic server events to clients.
- **`attachments.py`**: File upload and download routes.
- **`users.py` / `admin.py`**: Endpoints to manage dashboard users and administrative features.
- **`health.py`**: Probes for Kubernetes and general monitoring.

#### `app/db/` (Database & ORM)
Manages the local PostgreSQL state.
- **`base.py`**: Sets up the SQLAlchemy Engine, connection pool (QueuePool), and the declarative `Base`.
- **`models.py`**: SQLAlchemy ORM definitions (e.g., `User`, `Company`).
- **`crud.py` / `crud_refresh_token.py`**: Create, Read, Update, Delete abstractions between routes and the ORM.
- **`migrations/`**: Alembic configuration folder holding schema migration scripts.
- **`audit.py` / `row_level_security.py`**: Mechanisms to enforce RLS based on tenant/company ID and utilities for database auditing.

#### `app/core/` (Security & App Configuration)
- Authentication mechanisms (e.g. JWT parsing, hashing), and standard logging or dependency configurations.

#### `app/middleware/`
- Custom FastAPI middlewares to intercept requests, such as injecting Tenant/Company IDs on requests to maintain tenant isolation or log database execution stats.

#### `app/odoo_client/`
- Wrappers around the standard `xmlrpc.client`. Encapsulates logic for communicating with the Odoo API to read/write ERP records.

#### `app/redis_client/`
- Wrappers for connecting to Redis. Heavily used to publish WebSocket events so multiple worker processes can sync real-time payloads.

#### `app/workers/`
- **`celery_app.py`**: Configuration for Celery background tasks using Redis as a broker. Handles async operations outside of the HTTP request-response cycle.

#### Root Configuration Files
- **`docker-compose.yml`**: Defines the deployment stack (FastAPI server, PostgreSQL, Redis, Celery workers, Grafana, Loki, Prometheus, Jaeger).
- **`create_test_user.py`**: Script to seed an initial administrative user.

---

## 3. Flutter Frontend (`flutter_frontend`) File-by-File Breakdown

The frontend follows a clean-architecture approach, utilizing Riverpod for state management.

### `lib/` Directory
The main source tree for the Flutter app.

- **`main.dart`**: Entry point of the app. Initializes the `ProviderScope` for Riverpod and launches the `MaterialApp`.
- **`app_router.dart`**: Configures `GoRouter`. Defines the app's navigation paths.
- **`injection_container.dart`**: Sets up global dependency overrides or singletons.

#### `lib/models/` (Data Models)
- Dart classes representing the data from the API. Parses the backend's JSON responses into strongly-typed objects.

#### `lib/pages/` (UI Screens)
Top-level screens presented to the user.
- **`login_page.dart`**: Authentication UI.
- **`dashboard_page.dart`**: The main entry screen post-authentication, wrapping a scaffold that likely contains a side/bottom navigation bar.
- **`branch_browser_menu.dart`**: Component for navigating branch data.
- **`contacts/`**: Screens for viewing and editing contacts/customers.
- **`threads/`**: Screens dedicated to the chat feature.

#### `lib/providers/` (State Management)
Riverpod providers bridging data logic to the UI.
- **`auth_provider.dart`**: Manages the current user's session state context and UI redirections.
- **`contacts_provider.dart`**: Exposes the list of contacts, handling caching, pagination, or state transitions.
- **`threads_provider.dart`**: Exposes chat channel states.
- **`router_provider.dart`**: Provides the reactive routing instance integrating with authentication to perform route guards.

#### `lib/repositories/` (Data Repositories)
Handles direct interactions with REST APIs via HTTP clients, isolating logic from the providers. For instance, `contacts_repository.dart` wraps `/api/v1/contacts/`.

#### `lib/services/` (Core Services & WebSockets)
- Contains generic API clients and WebSocket client implementations (`websocket_service.dart`, `discuss_ws_service.dart`) to receive real-time updates from FastAPI.

#### `lib/widgets/` & `lib/utils/`
- **`widgets/`**: Reusable custom UI components un-tied to a specific feature, like custom buttons or form wrappers.
- **`utils/`**: Utilities such as formatters, validators, extensions (like `sized_box_ops.dart`), and standard layout constants.
