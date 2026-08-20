.PHONY: migrate-up migrate-down migrate-create migrate-status migrate-force migrate-version help

# MySQL connection is configured via environment variables (DB_HOST, DB_PORT,
# DB_USER, DB_PASSWORD, DB_NAME) — see config.LoadConfig for defaults.
MIGRATIONS_DIR = ./database/migrations

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

migrate-up: ## Run all pending migrations
	@echo "Running migrations (MySQL)..."
	@go run cmd/migrate/main.go up
	@echo "Migrations applied successfully!"

migrate-down: ## Rollback the last migration
	@echo "Rolling back last migration..."
	@go run cmd/migrate/main.go down
	@echo "Migration rolled back successfully!"

migrate-create: ## Create a new migration file (usage: make migrate-create NAME=create_users_table)
	@if [ -z "$(NAME)" ]; then \
		echo "Error: NAME is required. Usage: make migrate-create NAME=your_migration_name"; \
		exit 1; \
	fi
	@migrate create -ext sql -dir $(MIGRATIONS_DIR) -seq $(NAME)
	@echo "Migration files created in $(MIGRATIONS_DIR)!"

migrate-status: ## Show current migration version
	@echo "Current migration status:"
	@go run cmd/migrate/main.go version

migrate-force: ## Force set migration version (usage: make migrate-force VERSION=1)
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION is required. Usage: make migrate-force VERSION=1"; \
		exit 1; \
	fi
	@echo "Forcing migration version to $(VERSION)..."
	@migrate -path $(MIGRATIONS_DIR) -database "mysql://$(DB_USER):$(DB_PASSWORD)@tcp($(DB_HOST):$(DB_PORT))/$(DB_NAME)" force $(VERSION)
	@echo "Migration version forced to $(VERSION)!"

migrate-version: ## Show available migration files
	@echo "Available migration files:"
	@ls -1 $(MIGRATIONS_DIR)/*.sql 2>/dev/null || echo "No migration files found"

# Development helpers
dev: ## Build and run the server in development mode
	@go build -o meerkat . && ./meerkat

test: ## Run all tests
	@go test ./... -v

build: ## Build the application
	@go build -o meerkat .

clean: ## Clean build artifacts
	@rm -f meerkat
	@echo "Build artifacts cleaned!"
