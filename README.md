# Docker image for Heroku PHP

Usage: `FROM ghcr.io/robuust/heroku-php`

Builds require BuildKit. Composer and Yarn downloads are cached
across builds using the same builder, including builds from different agents that
share that builder. Composer's cache is separate from the image; installed
dependencies remain in `vendor`.

Yarn consumers must use `nodeLinker: node-modules`. Yarn uses a shared global cache
(`enableGlobalCache=true`, `globalFolder=/var/cache/yarn`), configured through
environment variables and mounted during both install and rebuild. Downloaded
archives stay outside the image; installed packages remain in `node_modules`.
Plug'n'Play requires a different cache setup before it can be enabled. Yarn rebuild
still runs after copying the application source. Pruning the build cache clears
the shared downloads; later installs or rebuilds download missing packages again.

# Specifications

* Heroku 24
* Apache
* Nginx
* PHP 8.5.x with Redis, Imagick and PCov
* Composer 2
* Node 24.x
* Yarn 4.x
