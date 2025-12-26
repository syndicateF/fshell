.PHONY: build install clean

# Build binary
build:
	go build -ldflags="-s -w" -o x-fetch ./cmd/

# Install to ~/.local/bin (user-local install)
install: build
	mkdir -p $(HOME)/.local/bin
	cp x-fetch $(HOME)/.local/bin/
	@echo "Installed to ~/.local/bin/x-fetch"
	@echo "Make sure ~/.local/bin is in your PATH"

# Clean build artifacts
clean:
	rm -f x-fetch
	rm -f x-fetch.tmp

# Test cache functionality
test-fetch:
	./x-fetch holidays --force
	@echo "=== Cache created ==="
	@cat $(HOME)/.cache/x-shell/holidays.json | head -30
