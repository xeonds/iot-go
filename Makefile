.PHONY : run build

run:
	cd gateway && make run

build:
	(mkdir -p build)
	(cd app && make web)
	(cp -r app/build/web build)
	(cd gateway && make linux) && (cp gateway/gateway build/)