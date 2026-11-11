# Contributing

## Local build

Build an image locally and run the smoke test against it:

```shell
docker build -t phpyh-php:test .
tests/smoke.sh phpyh-php:test
```

The PHP version is set with the `PHP_VERSION` build argument (the tag of the `php:<version>-cli-alpine` base image, `8.5` by default),
the Xdebug version — with `XDEBUG` (an `install-php-extensions` spec, `xdebug` by default).
See the matrix in [build.yaml](.github/workflows/build.yaml) for the values used for each PHP version.

## Scheduled workflows

Two workflows run weekly on a schedule: [build.yaml](.github/workflows/build.yaml) rebuilds and republishes the images,
[php-versions.yaml](.github/workflows/php-versions.yaml) fails when the build matrix needs an update
(a PHP version is released, reaches end of life or leaves RC).
GitHub disables scheduled workflows in a public repository after 60 days without activity and sends an email beforehand.
Merging Dependabot pull requests keeps the repository active.
A disabled workflow is re-enabled with the "Enable workflow" button on its page in the Actions tab.
