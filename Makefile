.PHONY: build build-backend build-ui generate-code help
build: build-backend
build-backend: generate-code
	CGO_ENABLED=1 go build -o ./casa ./main.go
generate-code:
	./scripts/generate-code.sh
build-ui:
	@if [ -d UI ]; then cd UI && yarn install && yarn build; else echo 'UI submodule not initialized; skipping UI build.'; fi
help:
	@echo 'make build-backend | generate-code | build-ui'
