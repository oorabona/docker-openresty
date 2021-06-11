#!/bin/sh

# STEP 1 - Bootstrap : download and build prerequisites
install_prereq () {
  apk add --no-cache --virtual .build-deps \
    flex bison \
    yajl-dev \
    autoconf \
    libtool \
    automake \
    curl-dev \
    doxygen \
    coreutils \
    gd-dev \
    geoip-dev \
    libxslt-dev \
    perl-dev \
    readline-dev \
    zlib-dev \
    linux-headers \
    git \
    ${RESTY_ADD_PACKAGE_BUILDDEPS}
  apk add --no-cache \
    build-base \
    gd \
    geoip \
    libgcc \
    libxslt \
    zlib \
    curl \
    yajl \
    libintl \
    make \
    musl \
    outils-md5 \
    perl \
    unzip \
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
  export MODSECURITY_INC="/tmp/ModSecurity/headers/"
  export MODSECURITY_LIB="/tmp/ModSecurity/src/.libs/"
  cd /tmp
  git clone https://github.com/SpiderLabs/ModSecurity-nginx
  curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o openresty-${RESTY_VERSION}.tar.gz
  tar xzf openresty-${RESTY_VERSION}.tar.gz
  cd /tmp/openresty-${RESTY_VERSION}
  export RESTY_CONFIG_OPTIONS="--add-module=/tmp/ModSecurity-nginx ${RESTY_CONFIG_OPTIONS}"
  eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} ${RESTY_LUAJIT_OPTIONS}
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

install_modsecurity () {
  cd /tmp
  git clone https://github.com/SpiderLabs/ModSecurity
  cd ModSecurity
  # git checkout -b v3/master origin/v3/master
  sh build.sh
  git submodule init
  git submodule update
  ./configure --with-pcre=/usr/local/openresty/pcre
  make -j${RESTY_J}
  make -j${RESTY_J} install
  strip /usr/local/modsecurity/bin/* /usr/local/modsecurity/lib/*.a /usr/local/modsecurity/lib/*.so*
  ln -s /usr/local/modsecurity/lib/libmodsecurity.so.3 /usr/local/lib/libmodsecurity.so.3
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
install_modsecurity
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
