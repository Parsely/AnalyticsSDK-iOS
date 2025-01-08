# TODO: Use newer Sim. Sticking with it at the moment because we know it works in the existing GitHub action setup.
SIMULATOR_NAME ?= iPhone 14
SIMULATOR_OS ?= latest
XCODE_PATH ?= /Applications/Xcode.app

# Convenience to open the lib and demo project with Xcode, given it's not in the root.
open:
	open -a $(XCODE_PATH) ./Demo/ParselyDemo.xcodeproj

# TODO: Move off xcpretty to xcbeautify. Sticking with it at the moment because we know it works in the existing GitHub action setup.
test:
	set -o pipefail \
		&& xcodebuild test \
		-project Demo/ParselyDemo.xcodeproj \
		-scheme ParselyDemo \
		-sdk iphonesimulator \
		-destination 'platform=iOS Simulator,name=$(SIMULATOR_NAME),OS=$(SIMULATOR_OS)' \
		| xcpretty

# TODO: Add automation to set up SwiftLint
format:
	swiftlint --fix --format
