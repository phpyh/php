# CLAUDE.md

Every push to `main` publishes the images to the moving tags `ghcr.io/phpyh/php:<version>`: a merged change
reaches users without a release step, so treat every change of the image as user-facing.

## Verify a change

Run the linters and the smoke test from CONTRIBUTING.md. When the change depends on the PHP version, build
the versions from the matrix in `.github/workflows/build.yaml` that it affects.
Extend `tests/smoke.sh` when you add something to the image.

## Dockerfile

- `RUN <<EOF` bodies are indented with 4 spaces and start with `set -eux`. `COPY <<EOF` file contents are never
  indented: the indentation ends up in the file.
- The image must work with `--user` of any UID: whatever the user writes to at runtime is writable by any user.

## Changelog

Add every user-visible change of the image to `CHANGELOG.md`, in the same commit.

- Sections are the publish dates in UTC (`## 2026-11-11`): tags are moving, there are no versions and no `[Unreleased]`.
  Add to the section of today's date or create it on top.
- Group items under Added / Changed / Removed / Fixed (Keep a Changelog).
- Prefix incompatible changes with `**BC Break:**` and say in the same item what users have to do.

## README

README.md is for image users and stays compact: tags, usage, what's included, configuration.

- Don't mention what the image doesn't include.
- Rationale and migration steps go to the changelog, maintainer notes go to CONTRIBUTING.md.
