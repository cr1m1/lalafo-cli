.PHONY: build test lint install clean

BIN_EXT := $(if $(filter windows,$(shell go env GOOS)),.exe,)

build:
	go build -o bin/lalafo-pp-cli$(BIN_EXT) ./cmd/lalafo-pp-cli

test:
	go test ./...

lint:
	golangci-lint run

install:
	go install ./cmd/lalafo-pp-cli

clean:
	rm -rf bin/

build-mcp:
	go build -o bin/lalafo-pp-mcp$(BIN_EXT) ./cmd/lalafo-pp-mcp

install-mcp:
	go install ./cmd/lalafo-pp-mcp

build-all: build build-mcp
