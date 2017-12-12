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
        libpng-dev \
	--no-install-recommends && rm -r /var/lib/apt/lists/*

ENV BUILD_DIR /opt/goodrain/php
ENV APACHE_DIR /opt/goodrain/apache2
ENV PATH=$PATH:$BUILD_DIR/bin:$APACHE_DIR/bin
ENV PHP_INI_DIR $BUILD_DIR/etc
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

RUN curl -sk https://pkg.goodrain.com/dockerfile/apache/apache-${APACHE_VERSION}.tar.gz | tar xz -C /
COPY docker-php-ext-* docker-php-entrypoint /usr/local/bin/
COPY httpd-foreground /usr/local/bin/
COPY docker-php-source /usr/local/bin/
COPY build.sh /
RUN chmod +x /build.sh

CMD [ "/build.sh" ]