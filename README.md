# PHPyh development PHP images

[![Build](https://github.com/phpyh/php/actions/workflows/build.yaml/badge.svg)](https://github.com/phpyh/php/actions/workflows/build.yaml)

PHP Docker images for development and CI, built on top of `php:<version>-cli-alpine`.

## Images

Published to `ghcr.io/phpyh/php` for `linux/amd64` and `linux/arm64` on every push to `main` and every Monday,
so PHP patch releases, extensions and tools stay up to date.

| Tag                     | PHP                                                |
|-------------------------|----------------------------------------------------|
| `ghcr.io/phpyh/php:8.2` | 8.2 (no updates after security EOL on 31 Dec 2026) |
| `ghcr.io/phpyh/php:8.3` | 8.3                                                |
| `ghcr.io/phpyh/php:8.4` | 8.4                                                |
| `ghcr.io/phpyh/php:8.5` | 8.5                                                |
| `ghcr.io/phpyh/php:8.6` | 8.6 (RC until GA release)                          |

Each image is also tagged with the full PHP version, e.g. `ghcr.io/phpyh/php:8.5.12`.
Both tags are moving: they are rebuilt weekly with the latest extensions and tools.
For a reproducible environment, pin the image by digest:

```yaml
image: ghcr.io/phpyh/php:8.5@sha256:<digest>
```

Get the current digest with `docker buildx imagetools inspect ghcr.io/phpyh/php:8.5`.

## What's included

### System tools

- `make`
- `git`
- `unzip`

### Locale

`LC_ALL` is set to `C.UTF-8`, so CLI tools and PHP handle UTF-8 input and output correctly.

### User

The default user is `dev` (UID `1000`, GID `1000`) — the UID of the first user on most Linux systems,
so files in mounted volumes have matching ownership out of the box. The image also works with any other UID,
see [File permissions on Linux](#file-permissions-on-linux).

Git is configured with `safe.directory=*`, so it works in mounted repositories owned by another user.

### PHP extensions

- [`mbstring`](https://www.php.net/manual/en/book.mbstring.php) (multibyte string functions)
- [`opcache`](https://www.php.net/manual/en/book.opcache.php)
- [`xdebug`](https://xdebug.org) (pre-configured with `mode=off`, `client_host=host.docker.internal`, and `xdebug.log=/xdebug.log`, see [Xdebug](#xdebug))
- [`uv`](https://github.com/amphp/ext-uv) (`libuv` bindings for async I/O)
- [`pcntl`](https://www.php.net/manual/en/book.pcntl.php) (process control: fork, signals, child processes)
- [`sockets`](https://www.php.net/manual/en/book.sockets.php) (low-level socket interface)
- [`intl`](https://www.php.net/manual/en/book.intl.php) (internationalization via ICU: locales, formatting, collation)
- [`bcmath`](https://www.php.net/manual/en/book.bc.php) (arbitrary precision arithmetic)
- [`pgsql`](https://www.php.net/manual/en/book.pgsql.php) (native PostgreSQL interface)
- [`pdo_pgsql`](https://www.php.net/manual/en/ref.pdo-pgsql.php) (PDO driver for PostgreSQL)

### Composer

`COMPOSER_HOME` is set to `/composer`, and `/composer/vendor/bin` is appended to `PATH` (so it never shadows system binaries) —
global tools are available as commands without full path. The directory is writable by any user,
so `composer global require` works without `sudo`.

`c` is available as a short alias for `composer` (e.g. `c req x/y`).

### Quality Tools

Installed as global Composer packages.

- [php-cs-fixer](https://github.com/PHP-CS-Fixer/PHP-CS-Fixer), [phpyh/coding-standard](https://github.com/phpyh/coding-standard)
- [phpstan](https://phpstan.org), [phpstan-strict-rules](https://github.com/phpstan/phpstan-strict-rules), [phpstan-phpunit](https://github.com/phpstan/phpstan-phpunit)
- [rector](https://getrector.com)
- [composer-dependency-analyser](https://github.com/shipmonk-rnd/composer-dependency-analyser)
- [composer-normalize](https://github.com/ergebnis/composer-normalize)
- [infection](https://infection.github.io)

## PHP configuration

Drop any `.ini` file into `/usr/local/etc/php/conf.d/` — PHP picks it up automatically.

Via a volume mount:

```yaml
services:
  app:
    image: ghcr.io/phpyh/php:8.5
    volumes:
      - ./php.ini:/usr/local/etc/php/conf.d/99-local.ini
```

Or by extending the image:

```dockerfile
FROM ghcr.io/phpyh/php:8.5
COPY php.ini /usr/local/etc/php/conf.d/99-local.ini
```

## Usage

```yaml
# compose.yaml
services:
  app:
    image: ghcr.io/phpyh/php:8.5
    volumes:
      - .:/app
      - composer-cache:/composer/cache
    working_dir: /app

volumes:
  composer-cache:
```

Or as a one-off command:

```shell
docker run --rm -it -v "$PWD:/app" -w /app ghcr.io/phpyh/php:8.5 composer install
```

### File permissions on Linux

With bind mounts on Linux, files inside the container have the same numeric owner as on the host.
The container runs as `dev` with UID `1000`, which matches the host user on most systems.
If your UID is different (check with `id -u`), the container can't write to your project,
and files it does create are owned by UID `1000` on the host.

In that case, run the container as your host user: `user: <uid>:<gid>` in Compose
or `-u "$(id -u):$(id -g)"` with `docker run`. The image is prepared for this: Composer home,
Composer cache and the Xdebug log are writable by any user. There is no `/etc/passwd` entry
for such a user, so `HOME` is `/` and `git config --global` is not available; everything else works the same.

On macOS and Windows, Docker Desktop maps file ownership automatically, so UID doesn't matter.

### Composer cache

Mount a named volume to `/composer/cache` to keep the cache between container runs, as in the example above.
A bind mount of a host directory works too, but make sure the directory exists before the container starts:
otherwise Docker creates it owned by `root`, and Composer won't be able to write to it.

## Xdebug

Xdebug is installed, but disabled by default (`xdebug.mode=off`), so it doesn't slow PHP down.
Enable it for a single run with the `XDEBUG_MODE` environment variable:

```shell
# Code coverage
docker compose run --rm -e XDEBUG_MODE=coverage app vendor/bin/phpunit --coverage-html=var/coverage

# Step debugging of a CLI script
docker compose run --rm -e XDEBUG_MODE=debug -e XDEBUG_TRIGGER=1 app php script.php
```

### Step debugging in PhpStorm

Add to the service from [Usage](#usage):

```yaml
# compose.yaml
services:
  app:
    environment:
      # Must match the server name in PhpStorm (Settings → PHP → Servers) with path mappings for /app
      PHP_IDE_CONFIG: serverName=app
    extra_hosts:
      # Required on Linux only: Docker Desktop resolves host.docker.internal on its own
      - host.docker.internal:host-gateway
```

Xdebug connects to `host.docker.internal:9003`. If the IDE doesn't receive a connection, check `/xdebug.log` in the container.

## Development

Build an image locally and run the smoke test against it:

```shell
docker build -t phpyh-php:test .
tests/smoke.sh phpyh-php:test
```

The PHP version is set with the `PHP_VERSION` build argument (the tag of the `php:<version>-cli-alpine` base image, `8.5` by default),
the Xdebug version — with `XDEBUG` (an `install-php-extensions` spec, `xdebug` by default).
See the matrix in [build.yaml](.github/workflows/build.yaml) for the values used for each PHP version.

Two workflows run weekly on a schedule: [build.yaml](.github/workflows/build.yaml) rebuilds and republishes the images,
[php-versions.yaml](.github/workflows/php-versions.yaml) fails when the build matrix needs an update
(a PHP version is released, reaches end of life or leaves RC).
GitHub disables scheduled workflows in a public repository after 60 days without activity and sends an email beforehand.
Merging Dependabot pull requests keeps the repository active.
A disabled workflow is re-enabled with the "Enable workflow" button on its page in the Actions tab.

## License

MIT License — see [LICENSE](LICENSE) for details.
