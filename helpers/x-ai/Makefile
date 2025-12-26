.PHONY: build install clean test run

BINARY := x-ai
PREFIX := /usr/local/bin
SYSTEMD_USER := ~/.config/systemd/user

build:
	CGO_ENABLED=1 go build -o $(BINARY) ./cmd

run: build
	./$(BINARY) daemon

test: build
	./$(BINARY) test

install: build
	install -Dm755 $(BINARY) $(PREFIX)/$(BINARY)
	install -Dm644 systemd/x-ai.socket $(SYSTEMD_USER)/x-ai.socket
	install -Dm644 systemd/x-ai.service $(SYSTEMD_USER)/x-ai.service
	systemctl --user daemon-reload
	@echo "Installed. Enable with: systemctl --user enable --now x-ai.socket"

uninstall:
	systemctl --user disable --now x-ai.socket x-ai.service || true
	rm -f $(PREFIX)/$(BINARY)
	rm -f $(SYSTEMD_USER)/x-ai.socket $(SYSTEMD_USER)/x-ai.service
	systemctl --user daemon-reload

clean:
	rm -f $(BINARY)

deps:
	go mod tidy
	go mod download

status:
	./$(BINARY) status
