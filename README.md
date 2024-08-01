## Introduction
This is a Dockerfile to build a debian based container image running nginx and php-fpm 8.0.x / 7.4.x / 7.3.x / 7.2.x / 7.1.x / 7.0.x & Composer.

### Versioning
| Docker Tag | GitHub Release | Nginx Version | PHP Version | Debian Version | Composer
|-----|-------|-----|--------|--------|------|
| latest | master Branch |1.21.6 | 8.0.16 | buster | 2.0.13 |
| php80 | php80 Branch |1.21.6 | 8.0.16 | buster | 2.0.13 |
| php74 | php74 Branch |1.21.6 | 7.4.28 | buster | 2.0.13 |

## Building from source
To build from source you need to clone the git repo and run docker build:
```
$ git clone https://github.com/esoftplay/nginx-php.git
$ cd nginx-php
```

followed by
```
$ docker build -t nginx-php:php74 . # PHP 7.4.x
```

## Pulling from Docker Hub
```
$ docker pull esoftplay/nginx-php:latest
```

## Running
To run the container:
```
$ sudo docker run -d esoftplay/nginx-php:latest
```

Default web root:
```
/usr/share/nginx/html
```
