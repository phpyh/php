#!/bin/sh
# Smoke test of a built image: tests/smoke.sh <image>
set -eu

image=${1:?Usage: $0 <image>}

docker run --rm -i "$image" sh -eux <<'SH'
    test "$(whoami)" = dev
    php -v
    php -r '
        foreach (["Zend OPcache", "xdebug", "mbstring", "uv", "pcntl", "sockets", "intl", "bcmath", "pgsql", "pdo_pgsql"] as $ext) {
            extension_loaded($ext) || throw new Error("Extension {$ext} is not loaded");
        }
        xdebug_info("mode") === [] || throw new Error("Xdebug is not off by default");
    '
    make --version | head -n1
    git --version
    unzip -v | head -n1
    composer --version
    # Global tools share dependencies: none of them is held back below its latest version
    composer global outdated --direct --strict
    c --version
    php-cs-fixer --version
    phpstan --version
    # Turbo extension for this platform survived the pruning in the Dockerfile
    echo '<?php' > /tmp/turbo.php
    phpstan analyse -l 0 -vvv --no-progress /tmp/turbo.php 2>&1 | grep '^Turbo extension: enabled'
    rector --version
    composer-dependency-analyser --version
    composer normalize --help >/dev/null
    infection --version
SH

# Any user can use Composer, Xdebug log and Git in a repository owned by someone else
docker run --rm -i --user 12345:12345 "$image" sh -eux <<'SH'
    test -w /composer/cache
    test -w /composer/composer.json
    test -w /xdebug.log
    composer global show >/dev/null
    XDEBUG_MODE=debug php -r ''
    grep -q 'Log opened' /xdebug.log
    git -C /composer init -q
    git -C /composer status >/dev/null
SH
