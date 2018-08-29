#################################
#  OLM-broker - Build and Test  #
#################################

SHELL := /bin/bash
PKG   := github.com/operator-framework/olm-broker
CMDS  := $(addprefix bin/, $(shell go list ./cmd/... | xargs -I{} basename {}))
IMAGE_REPO := quay.io/coreos/olm-service-broker
IMAGE_TAG ?= "dev"

.FORCE:

.PHONY: build test clean vendor cover.out \
	vendor-update coverage coverage-html .FORCE

all: test build

test: cover.out

unit:
	go test -v -race ./pkg/...

cover.out:
	go test -v -race -coverprofile=cover.out -covermode=atomic \
		-coverpkg ./pkg/server/... ./pkg/...

coverage: cover.out
	go tool cover -func=cover.out

coverage-html: cover.out
	go tool cover -html=cover.out

build: $(CMDS)

# build versions of the binaries with coverage enabled
build-coverage: GENCOVER=true
build-coverage: $(CMDS)

$(CMDS): .FORCE
	@if [ cover-$(GENCOVER) = cover-true ]; then \
		echo "building bin/$(shell basename $@)" with coverage; \
		GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go test -o $@ -c -covermode=count -coverpkg ./pkg/server/... $(PKG)/cmd/$(shell basename $@); \
	else \
		echo "building bin/$(shell basename $@)"; \
		GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o $@ $(PKG)/cmd/$(shell basename $@); \
	fi

DEP := $(GOPATH)/bin/dep
$(DEP):
	go get -u github.com/golang/dep/cmd/dep

vendor: $(DEP)
	$(DEP) ensure -v -vendor-only

vendor-update: $(DEP)
	$(DEP) ensure -v

# TODO: add Dockerfile
#container: build
#	docker build -t $(IMAGE_REPO):$(IMAGE_TAG) .

clean:
	rm -rf bin
