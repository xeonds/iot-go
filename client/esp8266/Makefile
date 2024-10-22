u=/dev/ttyUSB0
i=10.0.0.137
s=10.0.0.186

build: esp8266.ino
	arduino-cli compile --fqbn esp8266:esp8266:generic esp8266.ino

upload: 
	arduino-cli upload -p $u --fqbn esp8266:esp8266:generic esp8266.ino

serial:
	screen $u 115200

on:
	curl -X POST "localhost:1234/api/control/1E80B5/action:on"

off:
	curl -X POST "localhost:1234/api/control/1E80B5/action:off"

plus:
	curl -X POST "localhost:1234/api/control/1E80B5/action:+"

minus:
	curl -X POST "localhost:1234/api/control/1E80B5/action:-"

get-status:
	curl $i/status

find-usb:
	ls /dev|grep USB
