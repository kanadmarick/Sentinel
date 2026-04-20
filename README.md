# Sentinel Monolith

Sentinel is a local-first observability and AI-orchestration stack with a Django core engine, a FastAPI ingestion service, Redis-backed Celery workers, and PostgreSQL persistence.

## Repository Structure

- `apps/core-engine`: Django app ("Brain")
- `apps/ingestion`: FastAPI ingestion service + Celery worker
- `apps/status-api`: FastAPI status API (ZMQ → Prometheus bridge)
- `apps/watchdog`: System telemetry publisher (ZMQ)
- `src/`: Shared utilities (vault_manager, generate_topology)
- `database/init_sentinel_db.sql`: Sentinel schema bootstrap for PostgreSQL
- `database/setup_vault.sh`: Script to provision Vault DB user/schema on local PostgreSQL
- `infra/docker/core.yml`: Core local services (db, brain, status-api, watchdog, prometheus)
- `infra/docker/ingestion.yml`: Ingestion stack (redis, ingestion, celery_worker)
- `infra/docker/observability.yml`: ELK/observability compose stack
- `Makefile`: Operational shortcuts for build/up/down/logs/migrations

## Architecture (Local Core)

- `db`: PostgreSQL 15 (`sentinel_db` container)
- `redis`: Redis 7 (`sentinel_redis` container)
- `brain`: Django core engine on `http://localhost:8000`
- `ingestion`: FastAPI service on `http://localhost:8001`

## Prerequisites

- Docker + Docker Compose
- GNU Make
- Python 3.10+ (for local scripts/tests outside containers)
- Local PostgreSQL access for Vault bootstrap (used by `database/setup_vault.sh`)

## Environment Variables

Create a `.env` file at repository root with at least:

```env
DB_USER=sentinel_admin
DB_PASSWORD=change_me
DB_NAME=sentinel_db
LEGION_IP=127.0.0.1

VAULT_DB_NAME=sentinel_vault
VAULT_DB_USER=sentinel_admin
VAULT_DB_PASS=change_me
```

Adjust values for your local environment.

## Quick Start

1. Build services:

```bash
make build
```

2. Start core stack:

```bash
make up
```

3. Tail app logs:

```bash
make logs
```

4. Stop services:

```bash
make down
```

## Vault Bootstrap

Initialize the Vault database/schema on local PostgreSQL:

```bash
bash database/setup_vault.sh
```

What it does:

- Loads `VAULT_*` variables from `.env`
- Creates Vault database and role if missing
- Grants privileges and applies `database/init_sentinel_db.sql`

## Django Migration Helpers

- Create migrations for a Django app:

```bash
make mm app=registry
```

- Apply all migrations:

```bash
make migrate
```

## Connectivity Check Script

Validate local Vault (PostgreSQL) and Redis connections:

```bash
python test_connection.py
```

## Celery Task App

`apps/ingestion/celery_app.py` defines the Redis-backed Celery app and sample tasks. It is baked into the ingestion Docker image (no host bind mount required). The worker is started via `docker-compose` as the `celery_worker` service in `infra/docker/ingestion.yml`.

## Observability Stack

Bring up Legion-side observability services:

```bash
make infra-up
```

Stop them:

```bash
make infra-down
```

## Useful Commands

- `make shell-brain`: shell into Django container
- `make shell-ingestion`: shell into FastAPI container
- `make shell-db`: open PostgreSQL shell in DB container
- `make clean`: remove containers, volumes, and prune Docker artifacts

## Smoke Tests

A basic smoke test script validates all core service endpoints:

```bash
bash test/test_reflex.sh
```

Checks:
- `http://localhost:8000/` — brain (Django core engine)
- `http://localhost:8001/status` — ingestion service health
- `http://localhost:8002/metrics` — status-api Prometheus metrics bridge

## Development Workflow (No Live Reload)

All services run entirely from their Docker images — there are no host bind mounts. This eliminates WSL2 / Docker Desktop mount-collision errors on Windows. Code changes require a rebuild:

```bash
make build       # rebuild all images
make up          # start all stacks
```

To rebuild a single service:

```bash
docker-compose -f infra/docker/core.yml build --no-cache brain
docker-compose -f infra/docker/ingestion.yml build --no-cache ingestion
```

## Service Health Endpoints

| Service | URL | Notes |
|---|---|---|
| brain | `http://localhost:8000/` | Django core engine |
| ingestion | `http://localhost:8001/status` | FastAPI, returns `{"status": "operational"}` |
| ingestion (ingest) | `http://localhost:8001/ingest/pulse` | POST endpoint |
| status-api | `http://localhost:8002/status` | ZMQ → FastAPI bridge |
| status-api (metrics) | `http://localhost:8002/metrics` | Prometheus scrape endpoint |

## Notes

- `docker-compose` command is used by the `Makefile`. If your machine only has `docker compose`, either install the standalone plugin or update the `DOCKER_COMPOSE` variable in `Makefile`.
- No host bind mounts are used — services are fully image-based for WSL2 + Docker Desktop compatibility.
- Core services are optimized for lightweight local development.