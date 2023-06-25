
default: help

.PHONY: help

help: ## Prints help information
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

run: ## Start development server
	hugo server -D

submodules: ## Updates submodules including the current theme
	git submodule update --remote --merge
