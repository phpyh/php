# PHPyh development PHP images

PHP Docker images for development and CI, built on top of `php:<version>-cli-alpine`.

## Images

Published every Monday to `ghcr.io/phpyh/php` for `linux/amd64` and `linux/arm64`.

| Tag                     | PHP |
|-------------------------|-----|
| `ghcr.io/phpyh/php:8.2` | 8.2 |
| `ghcr.io/phpyh/php:8.3` | 8.3 |
| `ghcr.io/phpyh/php:8.4` | 8.4 |
| `ghcr.io/phpyh/php:8.5` | 8.5 |

## What's included

### System tools

- `make`
- `git`
- `unzip`

### User

The default user is `dev` (UID `10001`, GID `10001`).
The UID and GID can be overridden at build time via `--build-arg UID=... --build-arg GID=...`
to match the host user and avoid file permission issues with mounted volumes.

### PHP extensions

- [`opcache`](https://www.php.net/manual/en/book.opcache.php)
- [`xdebug`](https://xdebug.org) (pre-configured with `mode=off`, `client_host=host.docker.internal`, and `xdebug.log=/xdebug.log`)
- [`uv`](https://github.com/amphp/ext-uv) (`libuv` bindings for async I/O)
- [`pcntl`](https://www.php.net/manual/en/book.pcntl.php) (process control: fork, signals, child processes)
- [`sockets`](https://www.php.net/manual/en/book.sockets.php) (low-level socket interface)
- [`intl`](https://www.php.net/manual/en/book.intl.php) (internationalization via ICU: locales, formatting, collation)
- [`bcmath`](https://www.php.net/manual/en/book.bc.php) (arbitrary precision arithmetic)
- [`pgsql`](https://www.php.net/manual/en/book.pgsql.php) (native PostgreSQL interface)
- [`pdo_pgsql`](https://www.php.net/manual/en/ref.pdo-pgsql.php) (PDO driver for PostgreSQL)

### Composer

`COMPOSER_HOME` is set to `/composer`, and `/composer/vendor/bin` is added to `PATH` —
global tools are available as commands without full path. The directory is owned by `dev`,
so `composer global require` works without `sudo`.

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
# docker-compose.yml
services:
  app:
    image: ghcr.io/phpyh/php:8.5
    volumes:
      - .:/app
      - ~/.composer/cache:/composer/cache
    working_dir: /app
```

## License

MIT License — see [LICENSE](LICENSE) for details.
