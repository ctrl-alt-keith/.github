.PHONY: help check

.DEFAULT_GOAL := check

help: ## List available repo-local Makefile targets with short descriptions.
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_.-]+:.*## / {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check: ## Run canonical local validation.
	@git diff --check
	@if command -v markdownlint-cli2 >/dev/null 2>&1; then \
		echo "Running markdownlint-cli2"; \
		markdownlint-cli2 "**/*.md"; \
	else \
		echo "markdownlint-cli2 is not installed."; \
		echo "Install markdownlint-cli2, then rerun 'make check'."; \
		exit 1; \
	fi
