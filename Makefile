.PHONY:build build-ui build-backend help

build: build-ui build-backend


build-ui:
	cd CasaOS-UI && yarn install && yarn build

build-backend:
	export CGO_ENABLED=1;export CGO_LDFLAGS=-static;go build -o ./casa main.go;upx --lzma --best casa

help:
	@echo "call john"
# CasaOS build helpers
.PHONY: generate-code build-backend

generate-code:
	./scripts/generate-code.sh

build-backend: generate-code
	go build -trimpath -o casaos ./main.go
