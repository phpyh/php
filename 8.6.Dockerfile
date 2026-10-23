# TODO: remove once mlocati/docker-php-extension-installer supports PHP 8.6
ARG PHP_VERSION=8.6-rc

FROM php:${PHP_VERSION}-cli-alpine

ARG UID=10001
ARG GID=10001
ARG XDEBUG_VERSION=3.6.0alpha1
ARG UV_VERSION=0.3.1

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

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

RUN <<EOF
    set -eux
    apk add --no-cache --virtual .build-deps \
        ${PHPIZE_DEPS} \
        linux-headers \
        oniguruma-dev \
        icu-dev \
        libpq-dev \
        libuv-dev

    docker-php-ext-install -j$(nproc) \
        mbstring \
        pcntl \
        sockets \
        intl \
        bcmath \
        pgsql \
        pdo_pgsql

    mkdir -p /usr/src/xdebug /usr/src/uv
    curl -sSLf https://github.com/xdebug/xdebug/archive/refs/tags/${XDEBUG_VERSION}.tar.gz | tar -xz -C /usr/src/xdebug --strip-components=1
    curl -sSLf https://github.com/amphp/ext-uv/archive/refs/tags/v${UV_VERSION}.tar.gz | tar -xz -C /usr/src/uv --strip-components=1
    (cd /usr/src/xdebug && phpize && ./configure && make -j$(nproc) && make install)
    (cd /usr/src/uv && phpize && ./configure --with-uv && make -j$(nproc) && make install)
    docker-php-ext-enable xdebug uv

    runDeps="$(
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }'
    )"
    apk add --no-cache ${runDeps} icu-data-full
    apk del --no-network .build-deps
    rm -rf /usr/src/xdebug /usr/src/uv /tmp/*
EOF

RUN <<EOF
    set -eux
    addgroup -g ${GID} dev
    adduser -u ${UID} -G dev -D dev

    mkdir -p ${COMPOSER_HOME}
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

    # TODO: remove once phpstan_turbo stops segfaulting on PHP 8.6 ZTS, see https://github.com/phpstan/phpstan/issues/15528
    rm -f ${COMPOSER_HOME}/vendor/phpstan/phpstan/turbo-ext/*/phpstan_turbo-8.6-zts.so
EOF
