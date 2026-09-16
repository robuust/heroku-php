# Docker image for Heroku PHP

Usage: `FROM ghcr.io/robuust/heroku-php`

Builds require BuildKit. Composer downloads and Yarn's download mirror are cached
across builds using the same builder, including builds from different agents that
share that builder. Composer's cache is separate from the image; installed
dependencies remain in `vendor`.

Yarn uses a project cache (`enableGlobalCache=false`) and a shared mirror
(`enableMirror=true`, `globalFolder=/var/cache/yarn`), configured through environment
variables. Project package archives remain in the image at the configured
`cacheFolder` (normally `.yarn/cache`), so Plug'n'Play and `yarn rebuild` do not depend
on the builder's mirror being available. Yarn rebuild still runs after copying the
application source. Pruning the build cache clears the shared downloads; later
builds download missing packages again.

# Specifications

* Heroku 24
* Apache
* Nginx
* PHP 8.4.x with Redis, Imagick and PCov
* Composer 2
* Node 24.x
* Yarn 4.x
