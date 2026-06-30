.PHONY: up down logs deploy rollback test lint

up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f

deploy:
	bash scripts/deploy-docker.sh

rollback:
	bash scripts/rollback-docker.sh

test:
	npm test

lint:
	npm run lint
