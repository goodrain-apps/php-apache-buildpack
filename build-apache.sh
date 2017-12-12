#!/bin/bash

set -eux

buildDeps='bzip2 ca-certificates dpkg-dev gcc libpcre++-dev libssl-dev make wget '

apt-get update

apt-get install -y --no-install-recommends -V $buildDeps


ddist() {
	local f="$1"; shift;
	local distFile="$1"; shift;
	local success=;
	local distUrl=;
	for distUrl in $APACHE_DIST_URLS; do
		if wget -O "$f" "$distUrl$distFile"; then
			success=1;
			break;
		fi;
	done;
[ -n "$success" ]
}

ddist 'httpd.tar.bz2' "httpd/httpd-$HTTPD_VERSION.tar.bz2"
echo "$HTTPD_SHA256 *httpd.tar.bz2" | sha256sum -c -

# see https://httpd.apache.org/download.cgi#verify
ddist 'httpd.tar.bz2.asc' "httpd/httpd-$HTTPD_VERSION.tar.bz2.asc"
export GNUPGHOME="$(mktemp -d)"
gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B1B96F45DFBDCCF974019235193F180AB55D9977
gpg --batch --verify httpd.tar.bz2.asc httpd.tar.bz2
rm -rf "$GNUPGHOME" httpd.tar.bz2.asc

mkdir -p src
tar -xf httpd.tar.bz2 -C src --strip-components=1
rm httpd.tar.bz2
cd src

patches() {
	while [ "$#" -gt 0 ]; do
	    local patchFile="$1"; shift
		local patchSha256="$1"; shift
		ddist "$patchFile" "httpd/patches/apply_to_$HTTPD_VERSION/$patchFile"
		echo "$patchSha256 *$patchFile" | sha256sum -c -
		patch -p0 < "$patchFile"
		rm -f "$patchFile"
	done
}
patches $HTTPD_PATCHES

gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"

./configure \
    --build="$gnuArch" \
    --prefix="$APACHE_DIR" \
    --enable-mods-shared='all ssl ldap cache proxy authn_alias mem_cache file_cache authnz_ldap charset_lite dav_lock disk_cache' 

make -j "$(nproc)"
make install

cd $APACHE_DIR
rm -rf man manual src

sed -ri -e 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g' \
		-e 's!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g' \
		"$APACHE_DIR/conf/httpd.conf"