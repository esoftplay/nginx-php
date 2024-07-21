FROM ubuntu:20.04

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive
ENV NGINX_VERSION 1.21.6-1~buster
ENV php_conf /etc/php/8.2/fpm/php.ini
ENV fpm_conf /etc/php/8.2/fpm/pool.d/www.conf
ENV COMPOSER_VERSION 2.0.13

# Install Basic Requirements
RUN buildDeps='curl gcc make autoconf libc-dev zlib1g-dev pkg-config' \
    && set -x \
    && apt-get update \
    && apt-get install --no-install-recommends $buildDeps --no-install-suggests -q -y gnupg2 dirmngr wget apt-transport-https lsb-release ca-certificates \
    && apt-get install --no-install-recommends --no-install-suggests -q -y \
            apt-utils \
            nano \
            zip \
            unzip \
            python2.7 \
            git \
            libmemcached-dev \
            libmagickwand-dev \
            net-tools \
            telnet \
            curl \
            rsync \
            libmcrypt-dev \
            openssh-client \
            vim \
            dtach

RUN apt-get update \
    && apt-get install openssl libssl-dev -y

# Download Nginx source code (replace with correct URL)
RUN curl -LO https://nginx.org/download/nginx-1.21.6.tar.gz \
    && tar -zxvf nginx-1.21.6.tar.gz \
    && cd nginx-1.21.6 \
    && ./configure \
      --prefix=/etc/nginx \
      --sbin-path=/usr/sbin/nginx \
      --modules-path=/usr/lib/nginx/modules \
      --conf-path=/etc/nginx/nginx.conf \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/nginx/access.log \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/run/nginx.lock \
      --user=nginx \
      --group=nginx \
      --with-http_ssl_module \
      --with-http_v2_module \
      --with-threads \
      --with-file-aio \
      --with-http_gzip_static_module \
      --with-http_realip_module \
    && make \
    && make install

RUN apt-get update \
    && apt-get install software-properties-common -y \
    && add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -q -y \
            php8.2-imap \
            php8.2-fpm \
            php8.2-cli \
            php8.2-bcmath \
            php8.2-dev \
            php8.2-common \
            php8.2-opcache \
            php8.2-readline \
            php8.2-mbstring \
            php8.2-curl \
            php8.2-gd \
            php8.2-imagick \
            php8.2-mysql \
            php8.2-zip \
            php8.2-pgsql \
            php8.2-intl \
            php8.2-xml \
            php-pear \
    && pecl -d php_suffix=8.2 install -o -f redis memcached \
    && mkdir -p /run/php

# Install pip for Python 2.7 explicitly
RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py \
    && python2.7 get-pip.py \
    && rm get-pip.py
RUN pip install wheel
RUN pip install supervisor supervisor-stdout

# Configure Supervisord & PHP
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d \
    && rm -rf /etc/nginx/conf.d/default.conf \
    && sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} \
    && sed -i -e "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" ${php_conf} \
    && sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} \
    && sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} \
    && sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} \
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/8.2/fpm/php-fpm.conf \
    && sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_children = 5/pm.max_children = 4/g" ${fpm_conf} \
    && sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" ${fpm_conf} \
    && sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" ${fpm_conf} \
    && sed -i -e "s/www-data/nginx/g" ${fpm_conf} \
    && sed -i -e "s/^;clear_env = no$/clear_env = no/" ${fpm_conf} \
    && echo "extension=redis.so" > /etc/php/8.2/mods-available/redis.ini \
    && echo "extension=memcached.so" > /etc/php/8.2/mods-available/memcached.ini \
    && echo "extension=imagick.so" > /etc/php/8.2/mods-available/imagick.ini \
    && ln -sf /etc/php/8.2/mods-available/redis.ini /etc/php/8.2/fpm/conf.d/20-redis.ini \
    && ln -sf /etc/php/8.2/mods-available/redis.ini /etc/php/8.2/cli/conf.d/20-redis.ini \
    && ln -sf /etc/php/8.2/mods-available/memcached.ini /etc/php/8.2/fpm/conf.d/20-memcached.ini \
    && ln -sf /etc/php/8.2/mods-available/memcached.ini /etc/php/8.2/cli/conf.d/20-memcached.ini \
    && ln -sf /etc/php/8.2/mods-available/imagick.ini /etc/php/8.2/fpm/conf.d/20-imagick.ini \
    && ln -sf /etc/php/8.2/mods-available/imagick.ini /etc/php/8.2/cli/conf.d/20-imagick.ini \
    # Install Composer
    && curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
    && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
    && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
    && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} \
    && rm -rf /tmp/composer-setup.php \
    # Clean up
    && rm -rf /tmp/pear \
    && apt-get purge -y --auto-remove $buildDeps \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# Set Python 2 as the default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1

RUN useradd -s /sbin/nologin -r nginx
RUN chown -R nginx:nginx /var/log/nginx

# Supervisor config
COPY ./supervisord.conf /etc/supervisord.conf

# Override nginx's default config
COPY ./default.conf /etc/nginx/conf.d/default.conf
COPY ./nginx.conf /etc/nginx/nginx.conf

# Override default nginx welcome page
COPY html /usr/share/nginx/html

# Copy Scripts
COPY ./start.sh /start.sh

EXPOSE 80

CMD ["/start.sh"]
