# Changelog

All notable changes to the images will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Image tags are moving, so changes are listed by the date (UTC) they were published.
Check when your local image was built with `docker image inspect --format '{{.Created}}' ghcr.io/phpyh/php:8.5`.

## 2026-11-11

### Added

- Tag each image with the full PHP version as well, e.g. `ghcr.io/phpyh/php:8.5.12`.
- Add OCI labels and annotations (source, revision, creation date, license).
- Add `c` alias for `composer`.
- Trust all Git directories (`safe.directory=*`), so Git works in mounted repositories owned by another user.
- Support running the image as any user (`--user`): Composer home, Composer cache and the Xdebug log are writable by any user.

### Changed

- **BC Break:** The `dev` user has UID/GID `1000` instead of `10001`, matching the host user on most Linux systems. Files created in your projects by the old image (`vendor/`, `var/`, even `composer.json`) stay owned by `10001` and can't be modified, e.g. `composer require` fails with `./composer.json is not writable`. Fix the ownership once per project: `sudo chown -R "$(id -u):$(id -g)" .` on Linux, `xattr -rd user.containers.override_stat .` on macOS, or delete the generated directories and reinstall dependencies.
- Move Xdebug defaults to `00-xdebug.ini`, so any `.ini` in `conf.d/` overrides them.
- Append Composer global bin to `PATH` instead of prepending it, so global packages no longer shadow system binaries.
- Keep only this platform's PHPStan turbo extension, the image is ~50 MB smaller.

### Removed

- **BC Break:** Remove the `UID` and `GID` build arguments. Run the container with `--user` to use another UID.
- **BC Break:** Remove global Infection. Install it per project with `composer require --dev infection/infection`, not with `composer global require`: a global copy sees only global test framework adapters, and its `infection/extension-installer` registers the project's adapters in the global copy instead of the project.
