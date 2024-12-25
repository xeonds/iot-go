.PHONY: build apk web clean

run:
	flutter run

clean:
	@echo "Cleaning flutter build..."
	@flutter clean

build: apk web

apk:
	@echo "Building flutter apk..."
	@flutter build apk --target-platform android-arm64 --split-per-abi

web:
	@echo "Building flutter web..."
	@flutter build web

send:
	@localsend build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
