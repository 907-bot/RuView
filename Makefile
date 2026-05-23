.PHONY: build build-backend build-frontend compose-up compose-down

build: build-backend build-frontend

build-backend:
	docker build -f Dockerfile.backend -t ruview-backend:local .

build-frontend:
	docker build -f Dockerfile.frontend -t ruview-frontend:local .

compose-up:
	docker compose up --build -d

compose-down:
	docker compose down
