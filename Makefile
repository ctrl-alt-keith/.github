.PHONY: help check check-github-config

.DEFAULT_GOAL := check

help: ## List available repo-local Makefile targets with short descriptions.
	@awk 'BEGIN {FS = ":.*## "}; /^[a-zA-Z0-9_.-]+:.*## / {printf "  %-24s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

check: check-github-config ## Run canonical local validation.
	@git diff --check
	@if command -v markdownlint-cli2 >/dev/null 2>&1; then \
		echo "Running markdownlint-cli2"; \
		markdownlint-cli2 "**/*.md" "#.worktrees/**"; \
	else \
		echo "markdownlint-cli2 is not installed."; \
		echo "Install markdownlint-cli2, then rerun 'make check'."; \
		exit 1; \
	fi

check-github-config: ## Validate GitHub automation configuration.
	@ruby tools/check_dependabot_config.rb
	@ruby tools/check_workflow_config.rb
	@ruby tests/test_check_workflow_config.rb
	@ruby tests/test_pull_request_template.rb
