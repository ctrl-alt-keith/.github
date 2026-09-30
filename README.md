# .github

Organization-level GitHub profile, community health, and configuration material
for `ctrl-alt-keith`.

## Contents

- [`profile/README.md`](profile/README.md) is the public organization profile.
- [`.github/`](.github/) contains the pull request template, Dependabot
  configuration, and validation workflow.
- [`Makefile`](Makefile) defines the repository's validation entrypoints.

## Validate changes

Install the same pinned Markdown linter version used by CI, then run:

```sh
npm install --global markdownlint-cli2@0.23.2 --ignore-scripts
make check
```

This validates the GitHub configuration, checks Markdown and Git whitespace,
and runs the same checks used by the repository workflow.
