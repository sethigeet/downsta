build-android:
	flutter build apk

build-linux:
	flutter build linux

generate-icons:
	flutter pub run flutter_launcher_icons:main

.PHONY: build-android build-android generate-icons