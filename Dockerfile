ARG PHP_VERSION=8.5

FROM php:${PHP_VERSION}-cli-alpine

ARG UID=10001
ARG GID=10001

ENV LC_ALL=C.UTF-8

ENV COMPOSER_HOME=/composer
ENV PATH="${COMPOSER_HOME}/vendor/bin:${PATH}"

RUN <<EOF
    set -eux
    apk add --no-cache \
        make \
        git \
        unzip
EOF

RUN <<EOF
    set -eux
    (curl -sSLf https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o - || echo 'return 1') | sh -s \
        @composer \
        opcache \
        uv \
        pcntl \
        sockets \
        intl \
        bcmath \
        pgsql \
        pdo_pgsql \
        xdebug
EOF

RUN <<EOF
    set -eux
    addgroup -g ${GID} dev
    adduser -u ${UID} -G dev -D dev

    chown -R dev:dev ${COMPOSER_HOME}

    touch /xdebug.log
    chown dev:dev /xdebug.log

    echo 'xdebug.mode=off' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
    echo 'xdebug.client_host=host.docker.internal' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
    echo 'xdebug.log=/xdebug.log' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
EOF

USER dev

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
EOF
