# AGENTS.md

This repository contains org-level GitHub configuration and profile material
for `ctrl-alt-keith`.

Use `ctrl-alt-keith/ai-workflow-playbook` as the shared workflow baseline.
This file is only the repo-local execution layer for `.github`.
Repo-local rules take precedence only for repository-specific behavior.

## Startup And Mode

- Start with `ai-workflow-playbook/docs/start-here.md`, then read this file.
- Before acting, select the interaction mode: implementation, review/audit, or
  orchestration/prompt-authoring mode using the playbook guidance.
- Implementation agents make explicit repo changes and carry them through
  validation, commit, push, and pull request delivery.
- Review/audit agents inspect and report without mutating this repository.
- Orchestration/prompt-authoring agents produce complete, self-contained
  handoffs unless explicitly asked to implement.

## Scope

- Org profile material.
- Org-level GitHub defaults, templates, and community health files if added
  later.
- Org metadata or configuration supported by GitHub.

## Non-Scope

- Project-specific docs.
- Repo-local workflow rules for other repositories.
- Implementation code.
- Reusable workflow policy that belongs in `ai-workflow-playbook`.

## File Placement

- Put organization profile content under `profile/`.
- Keep the root `README.md` limited to repository orientation.
- Put GitHub-supported community health files, templates, or defaults at the
  paths GitHub expects when they are added.
- Do not add project-specific docs, implementation code, or reusable workflow
  policy to this repository.

## Command Form

- Use direct command execution for ordinary repo commands, including
  `git ...`, `gh ...`, `make ...`, `python ...`, and repo-local scripts or
  tools.
- Before using `zsh`, `bash`, `sh`, `zsh -lc`, `bash -lc`, `sh -c`, aliases,
  or equivalent wrapper shells, check whether the command has a direct form.
- Use shell wrappers only when shell syntax is genuinely required.

## Validation

- Use `make check` as the canonical local validation entrypoint.
- `make check` runs `git diff --check` and Markdown lint with
  `markdownlint-cli2`.
- Inspect Markdown rendering, links, repository scope, and public-safe content
  when Markdown content changes.

## Branches

- Branch from current `origin/main`.
- Use focused, purpose-based names such as `docs/<short-name>` or
  `chore/<short-name>`.
- Keep branch scope limited to this repository.

## Pull Requests

- Target `main`.
- Include a clear summary of org-level GitHub/profile changes.
- Include validation notes describing the inspection performed.
