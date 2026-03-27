.PHONY: setup build run clean install dmg

DERIVED_DATA = build
APP_NAME = AutoLang
APP_PATH = $(DERIVED_DATA)/Build/Products/Release/$(APP_NAME).app

setup:
	@command -v xcodegen >/dev/null 2>&1 || { echo "Installing XcodeGen via Homebrew..."; brew install xcodegen; }
	xcodegen generate
	@echo "Generated $(APP_NAME).xcodeproj"

build: setup
	xcodebuild \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-configuration Release \
		-derivedDataPath $(DERIVED_DATA) \
		build

run: build
	open "$(APP_PATH)"

install: build
	cp -R "$(APP_PATH)" /Applications/
	@echo "Installed to /Applications/$(APP_NAME).app"

dmg: build
	@echo "Creating DMG..."
	rm -rf dmg_staging $(APP_NAME).dmg
	mkdir -p dmg_staging
	cp -R "$(APP_PATH)" dmg_staging/
	ln -s /Applications dmg_staging/Applications
	hdiutil create -volname "$(APP_NAME)" \
		-srcfolder dmg_staging \
		-ov -format UDZO \
		"$(APP_NAME).dmg"
	rm -rf dmg_staging
	@echo "Created $(APP_NAME).dmg"

clean:
	rm -rf $(DERIVED_DATA) $(APP_NAME).xcodeproj $(APP_NAME).dmg dmg_staging

open:
	@test -f $(APP_NAME).xcodeproj/project.pbxproj || $(MAKE) setup
	open $(APP_NAME).xcodeproj
