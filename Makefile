# Makefile

VERSION=$(shell git rev-parse --verify HEAD)
GOLANG_VERSION=1.7.1
LAP_CONTAINER_NAME=local_lap

# initialize
init:
	go get golang.org/x/tools/cmd/goimports
	go get github.com/fzipp/gocyclo
	go get github.com/smartystreets/goconvey
	go get github.com/kardianos/govendor
	go get github.com/golang/lint/golint

# analyze
govet:
	ls -d */ | grep -v "vendor" | xargs go tool vet -composites=false

golint: init
	golint ./... | grep -v "vendor" | pygmentize -O style=monokai -f console256 -g

goimports: init
	find . -type f -name '*.go' -not -path "./vendor/*" | xargs goimports -w

gocyclo: init
	find . -type f -name '*.go' -not -path "./vendor/*" | xargs gocyclo -over 25

# test
test:
	WEB_ENV=test govendor test -v -cover +local

goconvey: init
	goconvey -port 9000

# migration
goose-up:
	go get bitbucket.org/liamstask/goose/cmd/goose
	goose -env local up
	goose -env local status

goose-down:
	go get bitbucket.org/liamstask/goose/cmd/goose
	goose -env local down
	goose -env local status

# dependecy
govendor-sync:
	govendor sync
	govendor list +vendor

govendor-unused:
	govendor list +unused

# build
build-api:
	time O15VENDOREXPERIMENT=1 GOOS=linux GOARCH=amd64 go build -ldflags "-X main.version=$(VERSION) -X main.webEnv=local" -o dist/lap-api ./main.go

build-batch:
	time O15VENDOREXPERIMENT=1 GOOS=linux GOARCH=amd64 go build -ldflags "-X main.version=$(VERSION) -X main.webEnv=local" -o dist/lap-batch ./Gododir/main.go

build-all: build-api build-batch

# development
watch:
	# see ./Gododir/main.go
	go run ./Gododir/main.go watch --watch

logs:
	docker logs -f local_lap

check: govendor-unused govet golint goimports gocyclo test

# run
run-api: build-api
	docker exec -it $(LAP_CONTAINER_NAME) /opt/lap-api

run-batch: build-batch
	@echo target=$(target)
	docker exec -it $(LAP_CONTAINER_NAME) /opt/lap-batch $(target)

# shippable
ci: init
	# golint
	# golint
	# for package in $(go list ./... | grep -v '/vendor/'); do golint -set_exit_status $package; done
	# gocyclo
	# find . -type f -name '*.go' -not -path "./vendor/*" | xargs gocyclo -over 25
	# find . -type f -name '*.go' -not -path "./vendor/*" | xargs gocyclo -over 25 | xargs -r false
	# test
	make test

# release script for jenkins
release-build-alpine:
	# apline用のビルドgolang-alpineのコンテナを立ち上げて、api&batchをビルド(jenkinsで実行)
	@echo env=$(env)
	sudo docker run --rm -v ${WORKSPACE}/saigon-lap:/go -w /go/src/github.com/CyberAgent/saigon-lap \
    golang:$(GOLANG_VERSION)-alpine sh -c "go build -v -ldflags \"-X main.version=${VERSION} -X main.webEnv=${env} \" -o dist/lap-api ./main.go ; \
    go build -v -ldflags \"-X main.version=${VERSION} -X main.webEnv=${env} \" -o dist/lap-batch ./Gododir/main.go" -e VERSION=$(VERSION) -e env=$(env)

release-build-linux:
	# golangのコンテナを立ち上げて、api&batchをビルド(jenkinsで実行)
	@echo env=$(env)
	sudo docker run --rm -v ${WORKSPACE}/saigon-lap:/go -w /go/src/github.com/CyberAgent/saigon-lap \
    golang:$(GOLANG_VERSION) sh -c "go build -v -ldflags \"-X main.version=${VERSION} -X main.webEnv=${env} \" -o dist/lap-api ./main.go ; \
    go build -v -ldflags \"-X main.version=${VERSION} -X main.webEnv=${env} \" -o dist/lap-batch ./Gododir/main.go" -e VERSION=$(VERSION) -e env=$(env)
