.PHONY: linux-aarch64

linux-la64: main.go tidy
	CC=loongarch64-unknown-linux-gnu-gcc CXX=loongarch64-unknown-linux-gnu-g++ GOOS=linux GOARCH=loong64 go build

linux: main.go tidy
	go build

linux-aarch64: main.go tidy 
	CGO_ENABLED=1 CC=aarch64-linux-gnu-gcc CXX=aarch64-linux-gnu-g++ GOOS=linux GOARCH=arm64 go build -ldflags "-linkmode external -extldflags -static"
tidy: *.go go.mod go.sum */*.go
	go mod tidy

run: gateway
	./gateway

call-temperature:
	curl -X POST localhost:1234/api/control/test_client_1/action:get_temperature
