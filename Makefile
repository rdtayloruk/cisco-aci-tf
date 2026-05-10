.PHONY: up down bootstrap logs clean

up:
	docker compose up -d

down:
	docker compose down

bootstrap:
	./scripts/bootstrap.sh

logs:
	docker compose logs -f

clean:
	@echo "Stopping docker containers and removing volumes..."
	docker compose down -v --remove-orphans || true
	@echo "Deleting persistent Gitea and Runner data directories..."
	docker run --rm -v $(CURDIR):/workspace -w /workspace alpine rm -rf gitea_data runner_data
	@echo "Cleanup completed successfully!"
