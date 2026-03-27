.PHONY: setup build run clean install dmg release

DERIVED_DATA = build
APP_NAME = AutoLang
APP_PATH = $(DERIVED_DATA)/Build/Products/Release/$(APP_NAME).app

export DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

# --- Notarization config ---
# Only DEVELOPER_ID is required. TEAM_ID is extracted automatically.
# Store notarytool credentials once with:
#   xcrun notarytool store-credentials "AC_PASSWORD" \
#     --apple-id "you@email.com" --team-id "XXXXXXXXXX" --password "xxxx-xxxx-xxxx-xxxx"
TEAM_ID ?= $(shell echo "$(DEVELOPER_ID)" | grep -oE '\([A-Z0-9]+\)' | tr -d '()')

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

build-signed: setup
	@test -n "$(DEVELOPER_ID)" || { echo "Error: set DEVELOPER_ID"; exit 1; }
	xcodebuild \
		-project $(APP_NAME).xcodeproj \
		-scheme $(APP_NAME) \
		-configuration Release \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGN_IDENTITY="$(DEVELOPER_ID)" \
		CODE_SIGN_STYLE=Manual \
		OTHER_CODE_SIGN_FLAGS="--options=runtime --timestamp" \
		CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
		build
	@echo "Signed build at $(APP_PATH)"

notarize: build-signed
	@test -n "$(TEAM_ID)" || { echo "Error: set TEAM_ID"; exit 1; }
	@echo "Zipping for notarization..."
	ditto -c -k --keepParent "$(APP_PATH)" "$(APP_NAME).zip"
	@echo "Submitting to Apple (this may take a few minutes)..."
	xcrun notarytool submit "$(APP_NAME).zip" \
		--keychain-profile "AC_PASSWORD" \
		--wait
	@echo "Stapling notarization ticket..."
	xcrun stapler staple "$(APP_PATH)"
	rm -f "$(APP_NAME).zip"
	@echo "Notarization complete"

# Full release: sign → notarize → DMG
release: notarize
	@echo "Creating release DMG..."
	rm -rf dmg_staging $(APP_NAME).dmg
	mkdir -p dmg_staging
	cp -R "$(APP_PATH)" dmg_staging/
	ln -s /Applications dmg_staging/Applications
	hdiutil create -volname "$(APP_NAME)" \
		-srcfolder dmg_staging \
		-ov -format UDZO \
		"$(APP_NAME).dmg"
	rm -rf dmg_staging
	@echo "Release ready: $(APP_NAME).dmg (signed + notarized)"

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
	rm -rf $(DERIVED_DATA) $(APP_NAME).xcodeproj $(APP_NAME).dmg $(APP_NAME).zip dmg_staging

open:
	@test -f $(APP_NAME).xcodeproj/project.pbxproj || $(MAKE) setup
	open $(APP_NAME).xcodeproj
