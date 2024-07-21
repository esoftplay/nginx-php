## Introduction
This is a Dockerfile to build a debian based container image running nginx and php-fpm 8.2.x / 7.4.x & Composer.

### Versioning
| Docker Tag | GitHub Release | Nginx Version | PHP Version | Debian Version | Composer
|-----|-------|-----|--------|--------|------|
| latest | master Branch |1.21.6 | 8.0.16 | buster | 2.0.13 |
| php82 | php82 Branch |1.21.6 | 8.2.16 | buster | 2.0.13 |
| php74 | php74 Branch |1.21.6 | 7.4.28 | buster | 2.0.13 |

## Building from source
To build from source you need to clone the git repo and run docker build:
```
$ git clone https://github.com/esoftplay/nginx-php.git
$ cd nginx-php
```

followed by
```
$ docker build -t esoftplay/nginx-php:php82 . # PHP 8.2.x
```

## Pulling from Docker Hub
```
$ docker pull esoftplay/nginx-php:php82
```

## Running
To run the container:
```
$ sudo docker run -p 80:80 esoftplay/nginx-php:php82
```

Default web root:
```
/usr/share/nginx/html
```
