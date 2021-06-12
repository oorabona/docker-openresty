#!/bin/sh

install_prereq () {
  apk add --no-cache --virtual .build-deps \
    coreutils \
    gd-dev \
    geoip-dev \
    libxslt-dev \
    perl-dev \
    readline-dev \
    zlib-dev \
    ${RESTY_ADD_PACKAGE_BUILDDEPS}
  apk add --no-cache \
    git \
    build-base \
    gd \
    geoip \
    libgcc \
    libxslt \
    zlib \
    curl \
    libintl \
    linux-headers \
    make \
    musl \
    outils-md5 \
    perl \
    unzip \
    libmaxminddb \
    ${RESTY_ADD_PACKAGE_RUNDEPS}
}

install_openssl () {
  cd /tmp
  curl -fSL "${RESTY_OPENSSL_URL_BASE}/openssl-${RESTY_OPENSSL_VERSION}.tar.gz" -o openssl-${RESTY_OPENSSL_VERSION}.tar.gz
  tar xzf openssl-${RESTY_OPENSSL_VERSION}.tar.gz
  cd openssl-${RESTY_OPENSSL_VERSION}
  if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.1" ]
  then
    echo 'patching OpenSSL 1.1.1 for OpenResty'
    curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1
  fi
  if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.0" ] ; then
    echo 'patching OpenSSL 1.1.0 for OpenResty'
    curl -s https://raw.githubusercontent.com/openresty/openresty/ed328977028c3ec3033bc25873ee360056e247cd/patches/openssl-1.1.0j-parallel_build_fix.patch | patch -p1
    curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1
  fi
  ./config \
    no-threads shared zlib -g \
    enable-ssl3 enable-ssl3-method \
    --prefix=/usr/local/openresty/openssl \
    --libdir=lib \
    -Wl,-rpath,/usr/local/openresty/openssl/lib
  make -j${RESTY_J}
  make -j${RESTY_J} install_sw
}

install_pcre () {
  cd /tmp
  curl -fSL https://ftp.pcre.org/pub/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o pcre-${RESTY_PCRE_VERSION}.tar.gz
  tar xzf pcre-${RESTY_PCRE_VERSION}.tar.gz
  cd /tmp/pcre-${RESTY_PCRE_VERSION}
  ./configure \
    --prefix=/usr/local/openresty/pcre \
    --disable-cpp \
    --enable-jit \
    --enable-utf \
    --enable-unicode-properties
  make -j${RESTY_J}
  make -j${RESTY_J} install
}

install_openresty () {
  cd /tmp
  curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz
  tar xzf openresty-${RESTY_VERSION}.tar.gz
  curl -fSL https://github.com/chobits/ngx_http_proxy_connect_module/archive/master.tar.gz -o ngx_http_proxy_connect_module.tar.gz
  tar zxf ngx_http_proxy_connect_module.tar.gz
  export RESTY_CONFIG_OPTIONS="--add-module=/tmp/ngx_http_proxy_connect_module-master ${RESTY_CONFIG_OPTIONS}"
  cd /tmp/openresty-${RESTY_VERSION}
  eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} ${RESTY_LUAJIT_OPTIONS}
  cd build/nginx-*
  patch -p 1 < /tmp/ngx_http_proxy_connect_module-master/patch/proxy_connect_rewrite_1018.patch
  cd /tmp/openresty-${RESTY_VERSION}
  make -j${RESTY_J}
  make -j${RESTY_J} install
}

install_luarocks () {
  cd /tmp
  curl -fSL https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz -o luarocks-${LUAROCKS_VERSION}.tar.gz
  tar zxf luarocks-${LUAROCKS_VERSION}.tar.gz
  cd /tmp/luarocks-${LUAROCKS_VERSION}
  export PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin
  ./configure
  make -j${RESTY_J}
  make -j${RESTY_J} install
}

install_brotli () {
  cd /tmp
  git clone --recursive https://github.com/google/ngx_brotli.git
}

set -ex

# STEP 1 - Download and install prerequisites
install_prereq

cd /tmp
if [ -n "${RESTY_EVAL_PRE_CONFIGURE}" ]
then
  eval $(echo ${RESTY_EVAL_PRE_CONFIGURE})
fi

# STEP 2 - Build required software
install_openssl
install_pcre
install_brotli
install_openresty
install_luarocks

cd /tmp
if [ -n "${RESTY_EVAL_POST_MAKE}" ]
then
  eval $(echo ${RESTY_EVAL_POST_MAKE})
fi

# STEP 3 - Remove no longer needed packages, sources and installed packages
rm -rf /tmp/*
apk del .build-deps

# STEP 4 - Finish installation
mkdir -p /var/run/openresty
ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log
ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log
