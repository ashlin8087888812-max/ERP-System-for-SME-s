up:
	docker-compose up -d

down:
	docker-compose down

test:
	docker-compose exec fastapi pytest

migrate:
	docker-compose exec fastapi alembic upgrade head

shell:
	docker-compose exec fastapi python
