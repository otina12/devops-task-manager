.PHONY: up down logs deploy rollback test lint urls

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f

urls:
	@echo "App:            http://localhost:3000"
	@echo "Grafana:        http://localhost:3001  (admin/admin)"
	@echo "Prometheus:     http://localhost:9090"
	@echo "Alertmanager:   http://localhost:9093"
	@echo "Alert receiver: http://localhost:5001"
	@echo "cAdvisor:       http://localhost:8080"

deploy:
	bash scripts/deploy-docker.sh

rollback:
	bash scripts/rollback-docker.sh

test:
	npm test

lint:
	npm run lint
