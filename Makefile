# --- Variables ---
# All compose files now live under infra/docker/
COMPOSE_CORE = infra/docker/core.yml
COMPOSE_INGESTION = infra/docker/ingestion.yml
COMPOSE_INFRA = infra/docker/observability.yml
DOCKER = podman
ENV_EXPORT = set -a; . ./.env; set +a; export DB_USER="$$VAULT_DB_USER" DB_PASSWORD="$$VAULT_DB_PASS" DB_NAME="$$VAULT_DB_NAME";
DOCKER_COMPOSE = $(ENV_EXPORT) podman-compose

# --- Help Command ---
.PHONY: help build up down logs logs-brain logs-ingestion logs-prometheus logs-status logs-watchdog topology mm migrate infra-up infra-down shell-brain shell-ingestion shell-db clean docker-config

help:
	@echo "Sentinel Bunker Management Commands:"
	@echo "  make build          - Build all application services"
	@echo "  make up             - Start all services (Ingestion and Core)"
	@echo "  make down           - Stop all services"
	@echo "  make infra-up       - Start the Legion-side ELK/Observability stack"
	@echo "  make infra-down     - Stop the Legion-side stack"
	@echo "  make logs           - Tail logs from all running services"
	@echo "  make logs-brain     - Tail logs from Brain only"
	@echo "  make logs-ingestion - Tail logs from Ingestion only"
	@echo "  make logs-prometheus - Tail logs from Prometheus only"
	@echo "  make logs-status    - Tail logs from the Status API only"
	@echo "  make logs-watchdog  - Tail logs from the Watchdog only"
	@echo "  make topology       - Generate topology_map.md from docker-compose services"
	@echo "  make mm app=<name>  - Create migrations for a specific Django app"
	@echo "  make migrate        - Apply Django migrations in the Brain container"
	@echo "  make shell-brain    - Open a shell in the Brain container"
	@echo "  make shell-ingestion - Open a shell in the Ingestion container"
	@echo "  make shell-db       - Open psql in the DB container"
	@echo "  make docker-config  - Create local Docker config without keychain"
	@echo "  make clean          - Remove all containers and volumes (Fresh start)"

# No-op kept for compatibility if referenced elsewhere
docker-config:
	@true

# --- Execution Node Commands ---
# Note: Run these while in the Sentinel root
build:
	# Build images from both compose files to prevent image drift
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) build
	$(DOCKER_COMPOSE) -f $(COMPOSE_INGESTION) build

up:
	# Start the ingestion stack first to create the shared network
	$(DOCKER_COMPOSE) -f $(COMPOSE_INGESTION) up -d
	# Start the core stack which connects to the shared network
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) up -d
	@set -a; . ./.env; set +a; echo "🚀 Sentinel Core & Ingestion are running (Brain: $$BRAIN_HOST_PORT, Ingestion: $$INGESTION_HOST_PORT, Status API: $$STATUS_API_HOST_PORT, Prometheus: $$PROMETHEUS_HOST_PORT)."

down:
	# Stop both stacks
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) down
	$(DOCKER_COMPOSE) -f $(COMPOSE_INGESTION) down

logs:
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) -f $(COMPOSE_INGESTION) logs -f

logs-brain:
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) logs -f brain

logs-ingestion:
	$(DOCKER_COMPOSE) -f $(COMPOSE_INGESTION) logs -f ingestion celery_worker

logs-prometheus:
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) logs -f prometheus

logs-status:
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) logs -f status-api

logs-watchdog:
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) logs -f watchdog

topology:
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) run --rm -v $(CURDIR):/workspace -w /workspace status-api python src/generate_topology.py

# Create migrations for a specific Django app label, e.g. make mm app=registry
mm:
	@if [ -z "$(app)" ]; then \
		echo "Usage: make mm app=<django_app_label>"; \
		exit 1; \
	fi
	podman exec -i sentinel_brain python manage.py makemigrations $(app)

# Apply all migrations
migrate:
	podman exec -i sentinel_brain python manage.py migrate

# --- Legion Observability Node Commands ---
# Note: Run these while in the Sentinel root on your Legion
infra-up:
	$(DOCKER_COMPOSE) -f $(COMPOSE_INFRA) up -d
	@echo "📊 Observability Stack is running on the Legion."

infra-down:
	$(DOCKER_COMPOSE) -f $(COMPOSE_INFRA) down

# --- Utility Commands ---

# Access the Brain container's shell
shell-brain:
	podman exec -it sentinel_brain /bin/bash

# Access the Ingestion container's shell
shell-ingestion:
	podman exec -it sentinel_ingestion /bin/bash

# Access the DB container's psql shell
shell-db:
	podman exec -it sentinel_db psql -U sentinel_admin -d sentinel_db

# Remove all containers and volumes (fresh start)
clean:
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) down -v
	$(DOCKER_COMPOSE) -f $(COMPOSE_INGESTION) down -v
	podman system prune -f
	@echo "🧹 System cleaned."