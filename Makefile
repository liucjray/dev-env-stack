STOW_DIR ?= $(CURDIR)/stow
WINDOWS_TARGET ?= /mnt/c/Users/user
WSL_TARGET ?= $(HOME)

.PHONY: help install stow check preview clean

help:
	@echo "Targets:"
	@echo "  make install   - apply configs with install.sh"
	@echo "  make stow      - apply configs with stow directly"
	@echo "  make check     - syntax check install.sh"
	@echo "  make preview   - dry-run stow for both packages"
	@echo "  make clean     - remove stow links for both packages"

install:
	./install.sh

stow:
	stow -d "$(STOW_DIR)" -t "$(WINDOWS_TARGET)" windows
	stow -d "$(STOW_DIR)" -t "$(WSL_TARGET)" wsl

check:
	bash -n install.sh

preview:
	stow -n -v -d "$(STOW_DIR)" -t "$(WINDOWS_TARGET)" windows
	stow -n -v -d "$(STOW_DIR)" -t "$(WSL_TARGET)" wsl

clean:
	stow -D -d "$(STOW_DIR)" -t "$(WINDOWS_TARGET)" windows
	stow -D -d "$(STOW_DIR)" -t "$(WSL_TARGET)" wsl

