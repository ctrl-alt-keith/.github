# .github

Organization-level GitHub profile, community health, and configuration material
for `ctrl-alt-keith`.

## Contents

- [`profile/README.md`](profile/README.md) is the public organization profile.
- [`.github/`](.github/) contains the pull request template, Dependabot
  configuration, and Markdown lint workflow.
- [`Makefile`](Makefile) defines the repository's validation entrypoints.

## Validate changes

Install `markdownlint-cli2`, then run:

```sh
make check
```

This validates the GitHub configuration, checks Markdown and Git whitespace,
and runs the same checks used by the repository workflow.
