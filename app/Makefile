.PHONY: build

run:
	flutter run

build:
	@echo "Building flutter apk..."
	@flutter build apk --target-platform android-arm64 --split-per-abi

send:
	@localsend build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
