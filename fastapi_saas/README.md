# FastAPI SaaS Microservice

Multi-tenant, real-time orchestration gateway for Odoo-backed ERP/SCM.

## Architecture

- **FastAPI**: REST API & WebSockets
- **Postgres**: Global multi-tenant metadata & auth
- **Redis**: Pub/Sub & Celery Broker
- **Celery**: Background workers for Odoo sync
- **Odoo**: Tenant ERP data (XML-RPC)

## Setup

1. Copy `.env.example` to `.env`
2. Run `make up` to start services
3. Run `make migrate` to apply DB migrations

## Development

- `make up`: Start services
- `make down`: Stop services
- `make test`: Run tests
- `make shell`: Enter app shell
