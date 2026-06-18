.PHONY: ci pre-push-setup

ci:
	fvm flutter pub get
	fvm dart format --output=none --set-exit-if-changed .
	fvm flutter analyze
	fvm flutter test
	fvm dart run build_runner build
	git diff --exit-code

pre-push-setup:
	@printf '#!/bin/sh\nmake ci\n' > .git/hooks/pre-push
	@chmod +x .git/hooks/pre-push
	@echo "pre-push hook installed: .git/hooks/pre-push"
