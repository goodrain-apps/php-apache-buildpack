FROM debian:jessie

# persistent / runtime deps
ENV PHPIZE_DEPS \
    autoconf \
    dpkg-dev \
    file \
    g++ \
    gcc \
    libc-dev \
    make \
    pkg-config \
    re2c

RUN apt-get update && apt-get install -y \
    $PHPIZE_DEPS \
    ca-certificates \
    curl \
    libedit2 \
    libsqlite3-0 \
    libxml2 \
    xz-utils \
    libapr1 \
    libaprutil1 \
    libaprutil1-ldap \
    libapr1-dev \
    libaprutil1-dev \
    libpcre++0 \
    libssl1.0.0 \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
	--no-install-recommends && rm -r /var/lib/apt/lists/*

ENV HTTPD_VERSION 2.2.34
ENV HTTPD_SHA256 e53183d5dfac5740d768b4c9bea193b1099f4b06b57e5f28d7caaf9ea7498160
ENV HTTPD_PATCHES="CVE-2017-9798-patch-2.2.patch 42c610f8a8f8d4d08664db6d9857120c2c252c9b388d56f238718854e6013e46"
ENV APACHE_DIST_URLS \
	https://www.apache.org/dyn/closer.cgi?action=download&filename= \
	https://www-us.apache.org/dist/ \
	https://www.apache.org/dist/ \
	https://archive.apache.org/dist/


ENV BUILD_DIR /opt/goodrain
ENV APACHE_DIR $BUILD_DIR/apache2
ENV PHP_DIR $BUILD_DIR/php
ENV PATH=$PATH:$APACHE_DIR/bin:$PHP_DIR/bin
ENV PHP_INI_DIR $PHP_DIR/etc
RUN mkdir -p $PHP_INI_DIR/conf.d

ENV PHP_EXTRA_CONFIGURE_ARGS --with-apxs2
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

ENV GPG_KEYS 0BD78B5F97500D450838F95DFE857D9A90D90EC1 6E4F6AB321FDC07F2C332E3AC2BF0BC433CFC8B3

ENV PHP_VERSION 5.6.32
ENV APACHE_VERSION 2.2.34
ENV PHP_URL="https://secure.php.net/get/php-5.6.32.tar.xz/from/this/mirror" PHP_ASC_URL="https://secure.php.net/get/php-5.6.32.tar.xz.asc/from/this/mirror"
ENV PHP_SHA256="8c2b4f721c7475fb9eabda2495209e91ea933082e6f34299d11cba88cd76e64b" PHP_MD5=""

RUN set -xe; \
	\
	fetchDeps=' \
		wget \
	'; \
	if ! command -v gpg > /dev/null; then \
		fetchDeps="$fetchDeps \
			dirmngr \
			gnupg \
		"; \
	fi; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps; \
	rm -rf /var/lib/apt/lists/*; \
	\
	mkdir -p /usr/src; \
	cd /usr/src; \
	\
	wget -O php.tar.xz "$PHP_URL"; \
	\
	if [ -n "$PHP_SHA256" ]; then \
		echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -; \
	fi; \
	if [ -n "$PHP_MD5" ]; then \
		echo "$PHP_MD5 *php.tar.xz" | md5sum -c -; \
	fi; \
	\
	if [ -n "$PHP_ASC_URL" ]; then \
		wget -O php.tar.xz.asc "$PHP_ASC_URL"; \
		export GNUPGHOME="$(mktemp -d)"; \
		for key in $GPG_KEYS; do \
			gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
		done; \
		gpg --batch --verify php.tar.xz.asc php.tar.xz; \
		rm -rf "$GNUPGHOME"; \
	fi; \
	\
	apt-get purge -y $fetchDeps

COPY docker-php-ext-* docker-php-entrypoint /usr/local/bin/
COPY httpd-foreground /usr/local/bin/
COPY docker-php-source /usr/local/bin/
COPY build*.sh /
RUN chmod +x /build*.sh

CMD [ "/build.sh" ]