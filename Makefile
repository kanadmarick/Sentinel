# --- Variables ---
# Mac-side core services
COMPOSE_CORE = docker-compose.yml
# Legion-side infra services (referenced by path)
COMPOSE_INFRA = infra/docker/observability.yml
DOCKER = docker
DOCKER_CONFIG_LOCAL = $(CURDIR)/.docker-local
DOCKER_COMPOSE = DOCKER_CONFIG=$(DOCKER_CONFIG_LOCAL) docker-compose

# --- Help Command ---
help:
	@echo "Sentinel Bunker Management Commands:"
	@echo "  make build          - Build the Mac-side application services (Brain, Ingestion)"
	@echo "  make up             - Start the Mac core services (DB, Redis, Brain, Ingestion)"
	@echo "  make down           - Stop the Mac core services"
	@echo "  make infra-up       - Start the Legion-side ELK/Observability stack"
	@echo "  make infra-down     - Stop the Legion-side stack"
	@echo "  make logs           - Tail logs from Brain and Ingestion"
	@echo "  make logs-brain     - Tail logs from Brain only"
	@echo "  make logs-ingestion - Tail logs from Ingestion only"
	@echo "  make mm app=<name>  - Create migrations for a specific Django app"
	@echo "  make migrate        - Apply Django migrations in the Brain container"
	@echo "  make shell-brain    - Open a shell in the Brain container"
	@echo "  make shell-ingestion - Open a shell in the Ingestion container"
	@echo "  make shell-db       - Open psql in the DB container"
	@echo "  make docker-config  - Create local Docker config without keychain"
	@echo "  make clean          - Remove all containers and volumes (Fresh start)"

docker-config:
	@mkdir -p $(DOCKER_CONFIG_LOCAL)
	@if [ ! -f $(DOCKER_CONFIG_LOCAL)/config.json ]; then \
		echo '{"auths": {}}' > $(DOCKER_CONFIG_LOCAL)/config.json; \
	fi

# --- Mac Execution Node Commands ---
# Note: Run these while in the Sentinel root on your MacBook Air
build:
	@$(MAKE) docker-config
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) build

up:
	@$(MAKE) docker-config
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) up -d
	@echo "🚀 Sentinel Core is running on the MacBook Air."

down:
	@$(MAKE) docker-config
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) down

logs:
	@$(MAKE) docker-config
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) logs -f brain ingestion

logs-brain:
	@$(MAKE) docker-config
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) logs -f brain

logs-ingestion:
	@$(MAKE) docker-config
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) logs -f ingestion

# Create migrations for a specific Django app label, e.g. make mm app=registry
mm:
	@if [ -z "$(app)" ]; then \
		echo "Usage: make mm app=<django_app_label>"; \
		exit 1; \
	fi
	docker exec -i sentinel_brain python manage.py makemigrations $(app)

# Apply all migrations
migrate:
	docker exec -i sentinel_brain python manage.py migrate

# --- Legion Observability Node Commands ---
# Note: Run these while in the Sentinel root on your Legion
infra-up:
	@$(MAKE) docker-config
	$(DOCKER_COMPOSE) -f $(COMPOSE_INFRA) up -d
	@echo "📊 Observability Stack is running on the Legion."

infra-down:
	@$(MAKE) docker-config
	$(DOCKER_COMPOSE) -f $(COMPOSE_INFRA) down

# --- Utility Commands ---

# Access the Brain container's shell
shell-brain:
	docker exec -it sentinel_brain /bin/bash

# Access the Ingestion container's shell
shell-ingestion:
	docker exec -it sentinel_ingestion /bin/bash

# Access the DB container's psql shell
shell-db:
	docker exec -it sentinel_db psql -U sentinel_admin -d sentinel_db
# Access the Redis container's CLI
clean:
	@$(MAKE) docker-config
	$(DOCKER_COMPOSE) -f $(COMPOSE_CORE) down -v
	$(DOCKER) system prune -f
	@echo "🧹 System cleaned."