ARG PHP_VERSION=8.5

FROM php:${PHP_VERSION}-cli-bookworm

ARG UID=10001
ARG GID=10001

RUN <<EOF
    set -e
    groupadd --gid=${GID} app
    useradd --uid=${UID} --gid=${GID} --create-home --shell /bin/bash app
    apt-get update
    apt-get install --no-install-recommends --no-install-suggests -q -y unzip tini
EOF

ARG EXTENSIONS=''

RUN --mount=type=bind,from=mlocati/php-extension-installer:latest,source=/usr/bin/install-php-extensions,target=/usr/bin/install-extensions <<EOF
    set -e
    install-extensions @composer opcache pcntl sockets bcmath intl uv ${EXTENSIONS}
    apt-get remove -q -y ${PHPIZE_DEPS} ${BUILD_DEPENDS}
    ln -s /usr/local/bin/composer /usr/local/bin/c
    mkdir /var/.composer
    chown app:app /var/.composer
EOF

ENV COMPOSER_HOME=/var/.composer
ENV COMPOSER_CACHE_DIR=/var/.composer/cache
ENV PATH="/var/.composer/vendor/bin:${PATH}"

USER app

RUN <<EOF
    set -e
    composer global config allow-plugins.infection/extension-installer true
    composer global config allow-plugins.ergebnis/composer-normalize true
    composer global require --no-cache \
        friendsofphp/php-cs-fixer \
        phpyh/coding-standard \
        phpstan/phpstan \
        rector/rector \
        shipmonk/composer-dependency-analyser \
        ergebnis/composer-normalize \
        infection/infection
EOF

WORKDIR /app

ENTRYPOINT ["tini", "--"]
