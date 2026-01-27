# Bills Management API - Makefile

.PHONY: help build up down logs clean install dev test

# Default target
help: ## Show this help message
	@echo "Bills Management API - Available commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# Docker Operations
build: ## Build all containers
	docker-compose build

up: ## Start all services
	docker-compose up -d

up-logs: ## Start all services with logs
	docker-compose up

down: ## Stop all services
	docker-compose down

restart: ## Restart all services
	docker-compose restart

# Development
dev: ## Start in development mode with live reload
	docker-compose up -d postgres
	cd api && npm run dev

install: ## Install API dependencies
	cd api && npm install

# Logs and Monitoring
logs: ## Show logs for all services
	docker-compose logs -f

logs-api: ## Show API logs
	docker-compose logs -f api

logs-db: ## Show database logs
	docker-compose logs -f postgres

# Database Operations
db-shell: ## Connect to PostgreSQL shell
	docker-compose exec postgres psql -U postgres -d bills_db

db-reset: ## Reset database (⚠️  Deletes all data)
	docker-compose down -v
	docker-compose up -d

db-generate: ## Generate Prisma client
	docker-compose exec api npm run db:generate

db-push: ## Push Prisma schema to database
	docker-compose exec api npm run db:push

db-studio: ## Open Prisma Studio
	docker-compose exec api npm run db:studio

# Admin Tools
admin: ## Start with pgAdmin
	docker-compose --profile admin up -d

admin-down: ## Stop admin services
	docker-compose --profile admin down

# Testing and Quality
test: ## Run tests
	cd api && npm test

lint: ## Run linter
	cd api && npm run lint || echo "No lint script configured"

# Cleanup
clean: ## Remove all containers, images, and volumes
	docker-compose down -v --rmi all

clean-volumes: ## Remove only volumes (keeps images)
	docker-compose down -v

# Status
status: ## Show status of all services
	docker-compose ps

health: ## Check API health
	curl -f http://localhost:3000/health || echo "API not responding"

# Production
prod-up: ## Start in production mode
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d

prod-down: ## Stop production services
	docker-compose -f docker-compose.yml -f docker-compose.prod.yml down

# Quick Setup
setup: ## Quick setup - build and start everything
	@echo "🚀 Setting up Bills Management API..."
	@make build
	@make up
	@echo "✅ Setup complete!"
	@echo "📊 API: http://localhost:3000/health"
	@echo "🗄️  Database: localhost:5432"
	@echo "📋 Run 'make logs' to see service logs"

# Environment
env: ## Copy environment file
	cp api/.env.example api/.env
	@echo "📝 Environment file created at api/.env"
	@echo "⚠️  Please update the JWT_SECRET and other sensitive values"
