# AGENTS.md

This repository contains org-level GitHub configuration and profile material
for `ctrl-alt-keith`.

Use `ctrl-alt-keith/ai-workflow-playbook` as the shared workflow baseline.
This file is only the repo-local execution layer for `.github`.
Repo-local rules take precedence only for repository-specific behavior.

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

## Validation

- When this repository has no canonical validation command, validate by
  inspection.
- Inspect Markdown rendering, links, repository scope, and public-safe content.
- If a canonical validation command is later documented here, use that command
  instead.
- If a Makefile is later added, `make check` becomes the canonical path only
  when documented here.

## Branches

- Branch from current `origin/main`.
- Use focused, purpose-based names such as `docs/<short-name>` or
  `chore/<short-name>`.
- Keep branch scope limited to this repository.

## Pull Requests

- Target `main`.
- Include a clear summary of org-level GitHub/profile changes.
- Include validation notes describing the inspection performed.
