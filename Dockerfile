FROM ubuntu:22.04

# Let the container know that there is no tty
ENV DEBIAN_FRONTEND noninteractive
ENV NGINX_VERSION 1.21.6-1~buster
ENV php_conf /etc/php/7.4/fpm/php.ini
ENV fpm_conf /etc/php/7.4/fpm/pool.d/www.conf
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
            python-pip \
            python-setuptools \
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
            dtach \
            cron \
            curl

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
            php7.4-imap \
            php7.4-fpm \
            php7.4-cli \
            php7.4-bcmath \
            php7.4-dev \
            php7.4-common \
            php7.4-json \
            php7.4-opcache \
            php7.4-readline \
            php7.4-mbstring \
            php7.4-curl \
            php7.4-gd \
            php7.4-imagick \
            php7.4-mysql \
            php7.4-zip \
            php7.4-pgsql \
            php7.4-intl \
            php7.4-xml \
            php-pear \
    && pecl -d php_suffix=7.4 install -o -f redis memcached \
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
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/7.4/fpm/php-fpm.conf \
    && sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_children = 5/pm.max_children = 4/g" ${fpm_conf} \
    && sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" ${fpm_conf} \
    && sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" ${fpm_conf} \
    && sed -i -e "s/www-data/nginx/g" ${fpm_conf} \
    && sed -i -e "s/^;clear_env = no$/clear_env = no/" ${fpm_conf} \
    && echo "extension=redis.so" > /etc/php/7.4/mods-available/redis.ini \
    && echo "extension=memcached.so" > /etc/php/7.4/mods-available/memcached.ini \
    && ln -sf /etc/php/7.4/mods-available/redis.ini /etc/php/7.4/fpm/conf.d/20-redis.ini \
    && ln -sf /etc/php/7.4/mods-available/redis.ini /etc/php/7.4/cli/conf.d/20-redis.ini \
    && ln -sf /etc/php/7.4/mods-available/memcached.ini /etc/php/7.4/fpm/conf.d/20-memcached.ini \
    && ln -sf /etc/php/7.4/mods-available/memcached.ini /etc/php/7.4/cli/conf.d/20-memcached.ini \
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

# ADD mcrypt php module
RUN printf "\n" | pecl install mcrypt \
    && echo "extension = mcrypt.so" > /etc/php/7.4/mods-available/mcrypt.ini \
    && ln -s /etc/php/7.4/mods-available/mcrypt.ini /etc/php/7.4/fpm/conf.d/20-mcrypt.ini \
    && ln -s /etc/php/7.4/mods-available/mcrypt.ini /etc/php/7.4/cli/conf.d/20-mcrypt.ini

# ADD ioncube php module
RUN x=$( uname -m ) && x=$( echo "$x" | sed "s/_/-/" ) \
    && wget -O ioncube.tar.gz 'https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_'$x'.tar.gz' \
    && tar -xzf ioncube.tar.gz \
    && cp ioncube/ioncube_loader_lin_7.4.so /usr/lib/php/20190902/ioncube.so \
    && rm -rf ioncube.tar.gz ioncube \
    && echo "zend_extension = ioncube.so" > /etc/php/7.4/mods-available/ioncube.ini \
    && ln -s /etc/php/7.4/mods-available/ioncube.ini /etc/php/7.4/fpm/conf.d/10-ioncube.ini \
    && ln -s /etc/php/7.4/mods-available/ioncube.ini /etc/php/7.4/cli/conf.d/10-ioncube.ini

# Customize PHP.ini
RUN touch /etc/auto_prepend_file.php
RUN cp /etc/php/7.4/fpm/php.ini /etc/php/7.4/fpm/php.ini.orig
RUN cat /etc/php/7.4/fpm/php.ini.orig | sed \
     -e 's/short_open_tag = Off/short_open_tag = On/g' \
     -e 's/; max_input_vars = 1000/max_input_vars = 1000000/g' \
     -e 's/default_socket_timeout = 60/; default_socket_timeout = 60/g' \
     -e 's/auto_prepend_file =/auto_prepend_file = \/etc\/auto_prepend_file.php/g' \
     -e 's/html_errors = On/html_errors = Off/g' > /etc/php/7.4/fpm/php.ini

RUN cp /etc/php/7.4/cli/php.ini /etc/php/7.4/cli/php.ini.orig
RUN cat /etc/php/7.4/cli/php.ini.orig | sed \
     -e 's/short_open_tag = Off/short_open_tag = On/g' \
     -e 's/; max_input_vars = 1000/max_input_vars = 1000000/g' \
     -e 's/default_socket_timeout = 60/; default_socket_timeout = 60/g' \
     -e 's/auto_prepend_file =/auto_prepend_file = \/etc\/auto_prepend_file.php/g' \
     -e 's/html_errors = On/html_errors = Off/g' > /etc/php/7.4/cli/php.ini

# Set Python 2 as the default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1

RUN useradd -s /sbin/nologin -r nginx
RUN chown -R nginx:nginx /var/log/nginx

# Add esoftplay tools
RUN cd /opt && git clone https://github.com/esoftplay/tools.git

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
