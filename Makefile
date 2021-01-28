SHELL                    := /usr/bin/env bash
PWD                      := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

default: init

all: init

.PHONY: init
# Initialize project.
init: install-git-pre-commit-hooks

.PHONY: install-git-pre-commit-hooks
## Install Git pre-commit hooks.
install-git-pre-commit-hooks:
	pre-commit install --overwrite
