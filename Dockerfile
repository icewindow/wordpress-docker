FROM debian:bookworm


# Install Apache2 + PHP 8.2
ARG DEBIAN_FRONTEND=noninteractive
RUN set -ex; \
    apt-get update; \
    apt-get install -y apache2 libapache2-mod-php8.2 php8.2-cli php8.2-curl php8.2-gd php8.2-igbinary \
                       php8.2-intl php8.2-mbstring php8.2-mysql php8.2-opcache php8.2-xml php8.2-zip \
                       curl jq unzip; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    a2enmod rewrite expires; \
    touch /etc/apache2/sites-available/wordpress.conf; \
    a2dissite 000-default; \
    a2ensite wordpress


# Install Wordpress
ENV WORDPRESS_VERSION 6.4.3
ENV WORDPRESS_SHA1 ee3bc3a73ab3cfa535c46f111eb641b3467fa44e

RUN set -ex; \
	curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"; \
	echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c -; \
# upstream tarballs include ./wordpress/ so this gives us /var/www/wordpress
	tar -xzf wordpress.tar.gz -C /var/www/; \
	rm wordpress.tar.gz

VOLUME /var/www/wordpress/wp-content/uploads

# Add a themes/plugins installation wrapper scripts
COPY wp-install.sh /usr/local/bin/
COPY wp-locale.sh /usr/local/bin/

# Configure Apache, PHP and Wordpress
COPY apache2-foreground /usr/local/bin/
COPY wordpress.conf /etc/apache2/sites-available/
COPY opcache-recommended.ini /etc/php/8.2/apache2/conf.d/

# Configure apache/wordpress settings on the first run
COPY docker-entrypoint.sh /usr/local/bin/

# Set locales available by default.
ENV WORDPRESS_LOCALES en_US
RUN wp-locale.sh core

# Remove default plugins
WORKDIR /var/www/wordpress
RUN cd /var/www/wordpress/wp-content/plugins/; \
    rm -r akismet; \
    rm hello.php

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
