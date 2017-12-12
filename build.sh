#!/bin/bash

set -xe

/build-apache.sh \
&& /build-php.sh \
&& tar czvf /opt/package/apache-${APACHE_VERSION}.tar.gz $APACHE_DIR \
&& echo "Apache $APACHE_VERSION build completed successfully." \
&& tar czvf /opt/package/php-${PHP_VERSION}.tar.gz $PHP_DIR \
&& echo "PHP $PHP_VERSION build completed successfully."



