# Load environment variables from .env file if it exists
ifneq (,$(wildcard .env))
    include .env
    export
endif

# Dynamic UID/GID defaults if not already set in environment or .env
export USER_UID ?= $(shell id -u)
export USER_GID ?= $(shell id -g)

.PHONY: up down bootstrap logs clean init import

init: up bootstrap

up:
	docker compose up -d

down:
	docker compose down

bootstrap:
	./scripts/bootstrap.sh

import:
	./scripts/import-state.sh

logs:
	docker compose logs -f

clean:
	@echo "Stopping docker containers and removing volumes..."
	docker compose down -v --remove-orphans || true
	@echo "Deleting persistent Gitea and Runner data directories..."
	docker run --rm -v $(CURDIR):/workspace -w /workspace alpine rm -rf gitea_data runner_data
	@echo "Cleanup completed successfully!"
