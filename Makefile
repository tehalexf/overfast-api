# Default target
.DEFAULT_GOAL := help

# Colors
YELLOW := \033[1;33m
GREEN := \033[1;32m
CYAN := \033[1;36m
RESET := \033[0m

# Aliases
DOCKER_COMPOSE := docker compose

DOCKER_RUN := $(DOCKER_COMPOSE) run \
	--volume ${PWD}/app:/code/app \
	--volume ${PWD}/tests:/code/tests \
	--volume ${PWD}/htmlcov:/code/htmlcov \
	--volume ${PWD}/logs:/code/logs \
	--publish 8000:8000 \
	--rm \
	app

help: ## Show this help message
	@echo "Usage: make <command>"
	@echo ""
	@echo "${CYAN}Commands:${RESET}"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?##/ {printf "  ${GREEN}%-10s${RESET} : ${YELLOW}%s${RESET}\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build project images
	@echo "Building OverFastAPI (dev mode)..."
	BUILD_TARGET="dev" $(DOCKER_COMPOSE) build

start: ## Run OverFastAPI application (dev or testing mode)
ifdef TESTING_MODE
	@echo "Launching OverFastAPI (testing mode with reverse proxy)..."
	$(DOCKER_COMPOSE) --profile testing up -d
else
	@echo "Launching OverFastAPI (dev mode with autoreload)..."
	$(DOCKER_RUN) uv run fastapi dev app/main.py --host 0.0.0.0
endif

lint: ## Run linter
	@echo "Running linter..."
	$(DOCKER_RUN) uv run ruff check --fix --exit-non-zero-on-fix

format: ## Run formatter
	@echo "Running formatter..."
	$(DOCKER_RUN) uv run ruff format

shell: ## Access an interactive shell inside the app container
	@echo "Running shell on app container..."
	$(DOCKER_RUN) /bin/sh

exec: ## Execute a given COMMAND inside the app container
	@echo "Running command on app container..."
	$(DOCKER_RUN) $(COMMAND)

test:  ## Run tests, PYTEST_ARGS can be specified
ifdef PYTEST_ARGS
	@echo "Running tests on $(PYTEST_ARGS)..."
	$(DOCKER_RUN) uv run python -m pytest $(PYTEST_ARGS)
else
	@echo "Running all tests with coverage..."
	$(DOCKER_RUN) uv run python -m pytest --cov app/ --cov-report html -n auto tests/
endif

up: ## Build & run OverFastAPI application (production mode)
	@echo "Building OverFastAPI (production mode)..."
	$(DOCKER_COMPOSE) build
	@echo "Stopping OverFastAPI and cleaning containers..."
	$(DOCKER_COMPOSE) down -v --remove-orphans
	@echo "Launching OverFastAPI (production mode)..."
	$(DOCKER_COMPOSE) up -d

down: ## Stop the app and remove containers
	@echo "Stopping OverFastAPI and cleaning containers..."
	$(DOCKER_COMPOSE) --profile "*" down  -v --remove-orphans

clean: down ## Clean up Docker environment
	@echo "Cleaning Docker environment..."
	docker image prune -af
	docker network prune -f

lock: ## Update lock file
	uv lock

update_test_fixtures: ## Update test fixtures (heroes, players, etc.)
	$(DOCKER RUN) uv run python -m tests.update_test_fixtures $(PARAMS)

.PHONY: help build start lint format shell exec test up down clean lock update_test_fixtures