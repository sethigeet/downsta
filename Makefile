generate:
	flutter packages pub run build_runner build

generate-icons:
	flutter pub run flutter_launcher_icons:main

build-android:
	flutter build apk

build-linux:
	flutter build linux

.PHONY: generate generate-icons build-android build-linux