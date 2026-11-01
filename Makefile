.PHONY: build build-ui build-backend generate-code help

build: build-ui build-backend

generate-code:
	./scripts/generate-code.sh

build-ui:
	@if [ -d UI ]; then \
		cd UI && (command -v corepack >/dev/null 2>&1 && corepack enable >/dev/null 2>&1 || true) && yarn install --frozen-lockfile && yarn build; \
	else \
		echo "UI submodule is missing. Run: git submodule update --init --recursive"; \
		exit 1; \
	fi

build-backend: generate-code
	CGO_ENABLED=1 go build -o ./casa main.go

help:
	@echo "make generate-code  Generate CasaOS and Message Bus OpenAPI Go clients"
	@echo "make build-backend  Generate code and build the CasaOS backend"
	@echo "make build          Build UI and backend"
