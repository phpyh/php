ARG PHP_VERSION=8.5

FROM php:${PHP_VERSION}-cli-bookworm

ENV UID=10001
ENV GID=10001

RUN <<EOF
    set -eux
    groupadd --gid=${GID} dev
    useradd --uid=${UID} --gid=${GID} --create-home dev
    apt-get update
    apt-get install --no-install-recommends --no-install-suggests -q --yes \
        git \
        unzip \
        tini
EOF

RUN <<EOF
    set -eux
    (curl -sSLf https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o - || echo 'return 1') | sh -s \
        @composer \
        opcache \
        pcntl \
        sockets \
        bcmath \
        intl \
        uv \
        pcov
    apt-get remove -q --yes $(echo "${PHPIZE_DEPS}" | sed 's/\bmake\b//')
    ln -s /usr/local/bin/composer /usr/local/bin/c
    mkdir /composer
    chown dev:dev /composer
EOF

ENV COMPOSER_HOME=/composer
ENV COMPOSER_CACHE_DIR=/dev/null
ENV PATH="/composer/vendor/bin:${PATH}"

USER dev

RUN <<EOF
    set -eux
    echo '.idea/' >> '/home/dev/.gitignore'
    echo '/.playground/' >> '/home/dev/.gitignore'
    git config --global core.excludesFile '/home/dev/.gitignore'
EOF

RUN <<EOF
    set -eux
    composer global config allow-plugins.infection/extension-installer false
    composer global config allow-plugins.ergebnis/composer-normalize true
    composer global require --no-cache \
        friendsofphp/php-cs-fixer \
        phpyh/coding-standard \
        phpstan/phpstan \
        phpstan/phpstan-strict-rules \
        rector/rector \
        shipmonk/composer-dependency-analyser \
        ergebnis/composer-normalize \
        infection/infection
EOF

ENTRYPOINT ["tini", "--"]
