# --- Variables ---
# Mac-side core services
COMPOSE_CORE = docker-compose.yml
# Legion-side infra services (referenced by path)
COMPOSE_INFRA = infra/docker/observability.yml

# --- Help Command ---
help:
	@echo "Sentinel Bunker Management Commands:"
	@echo "  make build          - Build the Mac-side application (Brain)"
	@echo "  make up             - Start the Mac core services (DB, Redis, Brain)"
	@echo "  make down           - Stop the Mac core services"
	@echo "  make infra-up       - Start the Legion-side ELK/Observability stack"
	@echo "  make infra-down     - Stop the Legion-side stack"
	@echo "  make logs           - Tail logs from the Brain"
	@echo "  make clean          - Remove all containers and volumes (Fresh start)"

# --- Mac Execution Node Commands ---
# Note: Run these while in the Sentinel root on your MacBook Air
build:
	docker-compose -f $(COMPOSE_CORE) build

up:
	docker-compose -f $(COMPOSE_CORE) up -d
	@echo "🚀 Sentinel Core is running on the MacBook Air."

down:
	docker-compose -f $(COMPOSE_CORE) down

logs:
	docker-compose -f $(COMPOSE_CORE) logs -f brain

# --- Legion Observability Node Commands ---
# Note: Run these while in the Sentinel root on your Legion
infra-up:
	docker-compose -f $(COMPOSE_INFRA) up -d
	@echo "📊 Observability Stack is running on the Legion."

infra-down:
	docker-compose -f $(COMPOSE_INFRA) down

# --- Utility Commands ---

# Access the Brain container's shell
shell-brain:
	docker exec -it sentinel_brain /bin/bash
# Access the DB container's psql shell
shell-db:
	docker exec -it sentinel_db psql -U sentinel_admin -d sentinel_db
# Access the Redis container's CLI
clean:
	docker-compose -f $(COMPOSE_CORE) down -v
	docker system prune -f
	@echo "🧹 System cleaned."