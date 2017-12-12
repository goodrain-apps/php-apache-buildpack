#!/bin/bash
set -xe




fetchDeps='	wget'

if ! command -v gpg > /dev/null; then
	fetchDeps="$fetchDeps dirmngr gnupg	"
fi

apt-get update
apt-get install -y --no-install-recommends $fetchDeps
rm -rf /var/lib/apt/lists/*

mkdir -p /usr/src
cd /usr/src

wget -O php.tar.xz "$PHP_URL"

if [ -n "$PHP_SHA256" ]; then
	echo "$PHP_SHA256 *php.tar.xz" | sha256sum -c -
fi

if [ -n "$PHP_MD5" ]; then
	echo "$PHP_MD5 *php.tar.xz" | md5sum -c -
fi

if [ -n "$PHP_ASC_URL" ]; then
	wget -O php.tar.xz.asc "$PHP_ASC_URL"
	export GNUPGHOME="$(mktemp -d)"
	for key in $GPG_KEYS; do
		gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"
	done
	gpg --batch --verify php.tar.xz.asc php.tar.xz
	rm -rf "$GNUPGHOME"
fi

apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $fetchDeps

buildDeps="libcurl4-openssl-dev \
    libedit-dev libsqlite3-dev \
    libssl-dev libxml2-dev zlib1g-dev"

apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* 

export  CFLAGS="$PHP_CFLAGS" \
        CPPFLAGS="$PHP_CPPFLAGS" \
		LDFLAGS="$PHP_LDFLAGS" \
	&& docker-php-source extract \
	&& cd /usr/src/php \
	&& gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
	&& debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" \
	&& if [ ! -d /usr/include/curl ]; then \
		ln -sT "/usr/include/$debMultiarch/curl" /usr/local/include/curl; \
	fi \
	&& ./configure \
        --prefix=$BUILD_DIR \
		--build="$gnuArch" \
		--with-config-file-path="$PHP_INI_DIR" \
		--with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
		--disable-cgi \
		--enable-ftp \
		--enable-mbstring \
		--enable-mysqlnd \
		--with-curl \
		--with-libedit \
		--with-openssl \
		--with-zlib \
		$(test "$gnuArch" = 's390x-linux-gnu' && echo '--without-pcre-jit') \
		--with-libdir="lib/$debMultiarch" \
		$PHP_EXTRA_CONFIGURE_ARGS \
	&& make -j "$(nproc)" \
	&& make install \
	&& { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
	&& make clean \
	&& cd / \
	&& docker-php-source delete \
	&& apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps \
	&& pecl update-channels \
	&& rm -rf /tmp/pear ~/.pearrc \
    && docker-php-ext-install -j$(nproc) pdo pdo_mysql iconv mcrypt opcache \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd \
    && tar czvf /opt/package/php-${PHP_VERSION}.tar.gz $BUILD_DIR \
    && echo "PHP $PHP_VERSION build completed successfully."
