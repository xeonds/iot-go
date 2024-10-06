iot-go-gateway-loongarch64-unknown-linux-gnu: main.go
	go mod tidy
	CC=loongarch64-unknown-linux-gnu-gcc CXX=loongarch64-unknown-linux-gnu-g++ GOOS=linux GOARCH=loong64 go build -o iot-go-gateway-loongarch64-unknown-linux-gnu

iot-go-gateway-linux-amd64: main.go
	go mod tidy
	go build -o iot-go-gateway-linux-amd64


run: iot-go-gateway-linux-amd64
	./iot-go-gateway-linux-amd64
