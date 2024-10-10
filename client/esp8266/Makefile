u=/dev/ttyUSB1
i=10.0.0.139

build: esp8266.ino
	arduino-cli compile --fqbn esp8266:esp8266:generic esp8266.ino

upload: 
	arduino-cli upload -p $u --fqbn esp8266:esp8266:generic esp8266.ino

serial:
	screen $u 115200

pull-up:
	curl -X POST $i/control -d "status=1"

pull-down:
	curl -X POST $i/control -d "status=0"

get-status:
	curl $i/status
