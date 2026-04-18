ARG PHP_VERSION=8.5

FROM php:${PHP_VERSION}-cli-alpine

ARG UID=10001
ARG GID=10001

ENV LC_ALL=C.UTF-8

ENV COMPOSER_HOME=/home/dev/.composer
ENV PATH="${COMPOSER_HOME}/vendor/bin:${PATH}"

ARG XDEBUG_LOG=/home/dev/xdebug.log

RUN <<EOF
    set -eux
    apk add --no-cache \
        make \
        git \
        unzip
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
    ln -s /usr/local/bin/composer /usr/local/bin/c

    addgroup -g ${GID} dev
    adduser -u ${UID} -G dev -D dev

    chown -R dev:dev ${COMPOSER_HOME}

    echo 'xdebug.client_host=host.docker.internal' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
    echo 'xdebug.log=${XDEBUG_LOG}' >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
    touch ${XDEBUG_LOG}
    chown dev:dev ${XDEBUG_LOG}
EOF

USER dev

RUN <<EOF
    set -eux
    echo '.idea/' >> '/home/dev/.gitignore'
    echo '/.playground/' >> '/home/dev/.gitignore'
    git config --global core.excludesFile '/home/dev/.gitignore'
EOF

RUN --mount=type=cache,target=${COMPOSER_HOME}/cache,uid=${UID},gid=${GID} <<EOF
    set -eux
    composer global config allow-plugins.infection/extension-installer false
    composer global config allow-plugins.ergebnis/composer-normalize true
    composer global require \
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
