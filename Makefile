STOW_DIR ?= $(CURDIR)/stow
WINDOWS_TARGET ?= /mnt/c/Users/user
WSL_TARGET ?= $(HOME)
MACOS_TARGET ?= $(HOME)

.PHONY: help install stow check preview clean

help:
	@echo "Targets:"
	@echo "  make install        - apply configs with install.sh (auto-detects platform)"
	@echo "  make stow           - apply configs with stow directly (WSL)"
	@echo "  make stow-macos     - apply configs with stow directly (macOS)"
	@echo "  make check          - syntax check install.sh"
	@echo "  make preview        - dry-run stow (WSL)"
	@echo "  make preview-macos  - dry-run stow (macOS)"
	@echo "  make clean          - remove stow links (WSL)"
	@echo "  make clean-macos    - remove stow links (macOS)"

install:
	./install.sh

stow:
	stow -d "$(STOW_DIR)" -t "$(WINDOWS_TARGET)" windows
	stow -d "$(STOW_DIR)" -t "$(WSL_TARGET)" wsl

stow-macos:
	stow -d "$(STOW_DIR)" -t "$(MACOS_TARGET)" macos

check:
	bash -n install.sh

preview:
	stow -n -v -d "$(STOW_DIR)" -t "$(WINDOWS_TARGET)" windows
	stow -n -v -d "$(STOW_DIR)" -t "$(WSL_TARGET)" wsl

preview-macos:
	stow -n -v -d "$(STOW_DIR)" -t "$(MACOS_TARGET)" macos

clean:
	stow -D -d "$(STOW_DIR)" -t "$(WINDOWS_TARGET)" windows
	stow -D -d "$(STOW_DIR)" -t "$(WSL_TARGET)" wsl

clean-macos:
	stow -D -d "$(STOW_DIR)" -t "$(MACOS_TARGET)" macos

