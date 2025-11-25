ARG PHP_VERSION=8.3

FROM composer:2.9 AS composer
FROM mlocati/php-extension-installer:2.9 AS php-extension-installer
FROM php:${PHP_VERSION}-cli-bookworm

COPY --from=composer /usr/bin/composer /usr/bin/
COPY --from=php-extension-installer /usr/bin/install-php-extensions /usr/bin/

ARG UID=10001
ARG GID=10001

RUN <<EOF
    set -e
    groupmod --gid=${GID} www-data
    usermod --uid=${UID} --gid=${GID} www-data
    apt-get update
    apt-get install --no-install-recommends --no-install-suggests -q -y unzip tini
EOF

RUN <<EOF
    set -e
    install-php-extensions opcache pcntl sockets bcmath intl uv
    apt-get remove -q -y ${PHPIZE_DEPS} ${BUILD_DEPENDS}
EOF

RUN <<EOF
    set -e
    ln -s /usr/bin/composer /usr/bin/c
    mkdir /var/.composer
    chown www-data:www-data /var/.composer
EOF

ENV COMPOSER_HOME=/var/.composer
ENV COMPOSER_CACHE_DIR=/var/.composer/cache
ENV PATH="/var/.composer/vendor/bin:${PATH}"

USER www-data

RUN <<EOF
    set -e
    echo '{"config":{"allow-plugins":{"ergebnis/composer-normalize": true},"sort-packages":true}}' >> /var/.composer/composer.json
    composer global require --no-cache \
        ergebnis/composer-normalize \
        friendsofphp/php-cs-fixer \
        phpstan/phpstan \
        phpyh/coding-standard \
        rector/rector \
        shipmonk/composer-dependency-analyser
EOF

WORKDIR /app

ENTRYPOINT ["tini", "--"]
