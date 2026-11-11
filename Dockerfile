# syntax=docker/dockerfile:1

ARG PHP_VERSION=8.5

FROM php:${PHP_VERSION}-cli-alpine

ENV LC_ALL=C.UTF-8

ENV COMPOSER_HOME=/composer
ENV PATH="${COMPOSER_HOME}/vendor/bin:${PATH}"

RUN <<EOF
    set -eux
    apk add --no-cache \
        make \
        git \
        unzip
    # Mounted projects are often owned by a host user with a different UID
    git config --system --add safe.directory '*'
EOF

COPY --from=mlocati/php-extension-installer:2 /usr/bin/install-php-extensions /usr/local/bin/

ARG XDEBUG

RUN <<EOF
    set -eux
    install-php-extensions \
        @composer \
        mbstring \
        opcache \
        uv \
        pcntl \
        sockets \
        intl \
        bcmath \
        pgsql \
        pdo_pgsql \
        ${XDEBUG:-xdebug}
    ln -s /usr/local/bin/composer /usr/local/bin/c
EOF

# Loaded first, so any user .ini in conf.d/ can override these defaults
COPY <<EOF /usr/local/etc/php/conf.d/00-xdebug.ini
xdebug.mode=off
xdebug.client_host=host.docker.internal
xdebug.log=/xdebug.log
EOF

RUN <<EOF
    set -eux
    addgroup -g 1000 dev
    adduser -u 1000 -G dev -D dev
    chown -R dev:dev ${COMPOSER_HOME}
    # Writable for any user, so the image can run with --user matching the host UID
    touch /xdebug.log
    chmod 666 /xdebug.log
EOF

USER 1000:1000

RUN <<EOF
    set -eux
    composer global config allow-plugins.infection/extension-installer false
    composer global config allow-plugins.ergebnis/composer-normalize true
    composer global require --no-cache \
        friendsofphp/php-cs-fixer \
        phpyh/coding-standard \
        phpstan/phpstan \
        phpstan/phpstan-strict-rules \
        phpstan/phpstan-phpunit \
        rector/rector \
        shipmonk/composer-dependency-analyser \
        ergebnis/composer-normalize \
        infection/infection
    # Writable for any user, so the image can run with --user matching the host UID
    mkdir -p ${COMPOSER_HOME}/cache
    chmod -R a+rwX ${COMPOSER_HOME}
EOF
