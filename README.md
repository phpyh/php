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

Notable changes, including breaking ones, are listed in [CHANGELOG.md](CHANGELOG.md).

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

### File permissions

The container runs as `dev` with UID `1000`, the UID of the first user on most Linux systems.
On Linux, bind-mounted files keep their numeric owner, so if your UID is different (`id -u`),
the container can't write to your project. Run it as your host user then: `user: <uid>:<gid>` in Compose
or `-u "$(id -u):$(id -g)"` with `docker run`. Composer home, Composer cache and the Xdebug log are writable by any user.
Such a user has no `/etc/passwd` entry, so `HOME` is `/` and `git config --global` is not available.

On macOS and Windows, Docker Desktop remembers the owner of files created in the container,
and a container running with another UID can't modify them. Always run the container with the same UID.

### Composer cache

Mount a named volume to `/composer/cache` to keep the cache between runs, as in the example above.
To bind-mount a host directory instead, create it first, otherwise Docker creates it owned by `root`.

## What's included

- `make`, `git` and `unzip`
- `LC_ALL=C.UTF-8`, so CLI tools and PHP handle UTF-8 correctly
- User `dev` with UID/GID `1000`, see [File permissions](#file-permissions)
- Git trusts all directories (`safe.directory=*`), so it works in mounted repositories owned by another user
- PHP extensions:
  [`bcmath`](https://www.php.net/manual/en/book.bc.php),
  [`intl`](https://www.php.net/manual/en/book.intl.php),
  [`mbstring`](https://www.php.net/manual/en/book.mbstring.php),
  [`opcache`](https://www.php.net/manual/en/book.opcache.php),
  [`pcntl`](https://www.php.net/manual/en/book.pcntl.php),
  [`pdo_pgsql`](https://www.php.net/manual/en/ref.pdo-pgsql.php),
  [`pgsql`](https://www.php.net/manual/en/book.pgsql.php),
  [`sockets`](https://www.php.net/manual/en/book.sockets.php),
  [`uv`](https://github.com/amphp/ext-uv) and
  [`xdebug`](https://xdebug.org) (off by default, see [Xdebug](#xdebug))
- [Composer](https://getcomposer.org) with a short alias `c`. `COMPOSER_HOME` is `/composer` and is writable by any user,
  `/composer/vendor/bin` is appended to `PATH`, so global tools run by name and never shadow system binaries
- Quality tools as global Composer packages:
  - [php-cs-fixer](https://github.com/PHP-CS-Fixer/PHP-CS-Fixer), [phpyh/coding-standard](https://github.com/phpyh/coding-standard)
  - [phpstan](https://phpstan.org), [phpstan-strict-rules](https://github.com/phpstan/phpstan-strict-rules), [phpstan-phpunit](https://github.com/phpstan/phpstan-phpunit)
  - [rector](https://getrector.com)
  - [composer-dependency-analyser](https://github.com/shipmonk-rnd/composer-dependency-analyser)
  - [composer-normalize](https://github.com/ergebnis/composer-normalize)

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
