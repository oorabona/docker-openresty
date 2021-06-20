# Dockerfile - alpine
# https://github.com/oorabona/docker-openresty

ARG RESTY_IMAGE_BASE="alpine"
ARG RESTY_IMAGE_TAG="3.13"
ARG RESTY_FLAVOR="basic"

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG} AS base

RUN apk add --no-cache \
    git \
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
    libmaxminddb \
    ${RESTY_ADD_PACKAGE_RUNDEPS}

WORKDIR /tmp

FROM base AS build

# Docker Build Arguments
ARG RESTY_OPENSSL_VERSION="1.1.1k"
ARG RESTY_OPENSSL_PATCH_VERSION="1.1.1f"
ARG RESTY_OPENSSL_URL_BASE="https://www.openssl.org/source"
ARG RESTY_PCRE_VERSION="8.44"
ARG RESTY_J="4"

RUN apk add --no-cache --virtual .build-deps \
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
    ${RESTY_ADD_PACKAGE_BUILDDEPS}

RUN  curl -fSL "${RESTY_OPENSSL_URL_BASE}/openssl-${RESTY_OPENSSL_VERSION}.tar.gz" -o - | tar xzf - \
  && cd openssl-${RESTY_OPENSSL_VERSION} \
  && if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.1" ] ; then \
    echo 'patching OpenSSL 1.1.1 for OpenResty' ;\
    curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1 ; fi \
  && if [ $(echo ${RESTY_OPENSSL_VERSION} | cut -c 1-5) = "1.1.0" ] ; then \
    echo 'patching OpenSSL 1.1.0 for OpenResty' ;\
    curl -s https://raw.githubusercontent.com/openresty/openresty/ed328977028c3ec3033bc25873ee360056e247cd/patches/openssl-1.1.0j-parallel_build_fix.patch | patch -p1 ;\
    curl -s https://raw.githubusercontent.com/openresty/openresty/master/patches/openssl-${RESTY_OPENSSL_PATCH_VERSION}-sess_set_get_cb_yield.patch | patch -p1; fi \
  && ./config \
    no-threads shared zlib -g \
    enable-ssl3 enable-ssl3-method \
    --prefix=/usr/local/openresty/openssl \
    --libdir=lib \
    -Wl,-rpath,/usr/local/openresty/openssl/lib \
  && make -j${RESTY_J} \
  && make -j${RESTY_J} install_sw

RUN  curl -fSL https://ftp.pcre.org/pub/pcre/pcre-${RESTY_PCRE_VERSION}.tar.gz -o - | tar xzf - \
  && cd /tmp/pcre-${RESTY_PCRE_VERSION} \
  && ./configure \
    --prefix=/usr/local/openresty/pcre \
    --disable-cpp \
    --enable-jit \
    --enable-utf \
    --enable-unicode-properties \
  && make -j${RESTY_J} \
  && make -j${RESTY_J} install

RUN  git clone --recursive https://github.com/google/ngx_brotli.git \
  && git clone --recursive https://github.com/leev/ngx_http_geoip2_module.git

#
# Build OpenResty 'basic' flavor
#
FROM build AS openresty-basic

ARG RESTY_VERSION="1.19.3.1"
ARG RESTY_CONFIG_OPTIONS="\
    --with-compat \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-threads \
    "
ARG RESTY_CONFIG_OPTIONS_MORE="\
  --add-module=/tmp/ngx_brotli \
  --add-dynamic-module=/tmp/ngx_http_geoip2_module \
  "
ARG RESTY_LUAJIT_OPTIONS="--with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'"
ARG RESTY_ADD_PACKAGE_BUILDDEPS=""
ARG RESTY_ADD_PACKAGE_RUNDEPS=""
ARG RESTY_EVAL_PRE_CONFIGURE=""
ARG RESTY_EVAL_POST_MAKE=""

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-pcre \
    --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include' \
    --with-ld-opt='-L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -Wl,-rpath,/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib' \
    "

# For Luarocks
ARG LUAROCKS_VERSION="3.3.1"

ARG RESTY_J="4"

RUN  curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o - | tar xzf - \
  && cd /tmp/openresty-${RESTY_VERSION} \
  && eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} ${RESTY_LUAJIT_OPTIONS} \
  && make -j${RESTY_J} \
  && make -j${RESTY_J} install

RUN  curl -fSL https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz -o - | tar zxf - \
  && cd /tmp/luarocks-${LUAROCKS_VERSION} \
  && export PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin \
  && ./configure \
  && make -j${RESTY_J} \
  && make -j${RESTY_J} install

#
# Build OpenResty 'connect' flavor
#
FROM build AS openresty-connect

ARG RESTY_VERSION="1.19.3.1"
ARG RESTY_CONFIG_OPTIONS="\
    --with-compat \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-threads \
    "

ARG RESTY_CONFIG_OPTIONS_MORE="\
  --add-module=/tmp/ngx_brotli \
  --add-dynamic-module=/tmp/ngx_http_geoip2_module \
  "
ARG RESTY_LUAJIT_OPTIONS="--with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'"
ARG RESTY_ADD_PACKAGE_BUILDDEPS=""
ARG RESTY_ADD_PACKAGE_RUNDEPS=""
ARG RESTY_EVAL_PRE_CONFIGURE=""
ARG RESTY_EVAL_POST_MAKE=""

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-pcre \
    --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include' \
    --with-ld-opt='-L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -Wl,-rpath,/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib' \
    "

# For Luarocks
ARG LUAROCKS_VERSION="3.3.1"

ARG RESTY_J="4"

RUN  curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o - | tar xzf - \
  && curl -fSL https://github.com/chobits/ngx_http_proxy_connect_module/archive/master.tar.gz -o ngx_http_proxy_connect_module.tar.gz \
  && tar zxf ngx_http_proxy_connect_module.tar.gz \
  && export RESTY_CONFIG_OPTIONS="--add-module=/tmp/ngx_http_proxy_connect_module-master ${RESTY_CONFIG_OPTIONS}" \
  && cd /tmp/openresty-${RESTY_VERSION} \
  && eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} ${RESTY_LUAJIT_OPTIONS} \
  && cd build/nginx-* \
  && patch -p 1 < /tmp/ngx_http_proxy_connect_module-master/patch/proxy_connect_rewrite_1018.patch \
  && cd /tmp/openresty-${RESTY_VERSION} \
  && make -j${RESTY_J} \
  && make -j${RESTY_J} install

RUN  curl -fSL https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz -o - | tar zxf - \
  && cd /tmp/luarocks-${LUAROCKS_VERSION} \
  && export PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin \
  && ./configure \
  && make -j${RESTY_J} \
  && make -j${RESTY_J} install

#
# Build OpenResty 'modsecurity' flavor
#
FROM build AS openresty-modsecurity

ARG RESTY_VERSION="1.19.3.1"
ARG RESTY_CONFIG_OPTIONS="\
    --with-compat \
    --with-file-aio \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_geoip_module=dynamic \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_image_filter_module=dynamic \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-http_xslt_module=dynamic \
    --with-ipv6 \
    --with-mail \
    --with-mail_ssl_module \
    --with-md5-asm \
    --with-pcre-jit \
    --with-sha1-asm \
    --with-stream \
    --with-stream_ssl_module \
    --with-stream_realip_module \
    --with-threads \
    "

ARG RESTY_CONFIG_OPTIONS_MORE="\
  --add-module=/tmp/ngx_brotli \
  --add-dynamic-module=/tmp/ngx_http_geoip2_module \
  "
ARG RESTY_LUAJIT_OPTIONS="--with-luajit-xcflags='-DLUAJIT_NUMMODE=2 -DLUAJIT_ENABLE_LUA52COMPAT'"
ARG RESTY_ADD_PACKAGE_BUILDDEPS=""
ARG RESTY_ADD_PACKAGE_RUNDEPS=""
ARG RESTY_EVAL_PRE_CONFIGURE=""
ARG RESTY_EVAL_POST_MAKE=""

# These are not intended to be user-specified
ARG _RESTY_CONFIG_DEPS="--with-pcre \
    --with-cc-opt='-DNGX_LUA_ABORT_AT_PANIC -I/usr/local/openresty/pcre/include -I/usr/local/openresty/openssl/include' \
    --with-ld-opt='-L/usr/local/openresty/pcre/lib -L/usr/local/openresty/openssl/lib -Wl,-rpath,/usr/local/openresty/pcre/lib:/usr/local/openresty/openssl/lib' \
    "

# For Luarocks
ARG LUAROCKS_VERSION="3.3.1"

ARG RESTY_J="4"

RUN  git clone https://github.com/SpiderLabs/ModSecurity \
  && cd ModSecurity \
  && sh build.sh \
  && git submodule init \
  && git submodule update \
  && ./configure --with-pcre=/usr/local/openresty/pcre \
  && make -j${RESTY_J} \
  && make -j${RESTY_J} install \
  && strip /usr/local/modsecurity/bin/* /usr/local/modsecurity/lib/*.a /usr/local/modsecurity/lib/*.so* \
  && ln -s /usr/local/modsecurity/lib/libmodsecurity.so.3 /usr/local/lib/libmodsecurity.so.3

RUN  export MODSECURITY_INC="/tmp/ModSecurity/headers/" \
  && export MODSECURITY_LIB="/tmp/ModSecurity/src/.libs/" \
  && git clone https://github.com/SpiderLabs/ModSecurity-nginx \
  && curl -fSL https://openresty.org/download/openresty-${RESTY_VERSION}.tar.gz -o - | tar zxf - \
  && cd /tmp/openresty-${RESTY_VERSION} \
  && export RESTY_CONFIG_OPTIONS="--add-module=/tmp/ModSecurity-nginx ${RESTY_CONFIG_OPTIONS}" \
  && eval ./configure -j${RESTY_J} ${_RESTY_CONFIG_DEPS} ${RESTY_CONFIG_OPTIONS} ${RESTY_CONFIG_OPTIONS_MORE} ${RESTY_LUAJIT_OPTIONS} \
  && cd /tmp/openresty-${RESTY_VERSION} \
  && make -j${RESTY_J} \
  && make -j${RESTY_J} install

RUN  curl -fSL https://luarocks.org/releases/luarocks-${LUAROCKS_VERSION}.tar.gz -o - | tar zxf - \
  && cd /tmp/luarocks-${LUAROCKS_VERSION} \
  && export PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin \
  && ./configure \
  && make -j${RESTY_J} \
  && make -j${RESTY_J} install

#
# A bit hacky but that's the way to build conditionally
#
FROM openresty-${RESTY_FLAVOR} AS openresty

#
# Build final image
#
FROM base

COPY --from=openresty /usr/local/ /usr/local/

RUN  mkdir -p /var/run/openresty \
  && ln -sf /dev/stdout /usr/local/openresty/nginx/logs/access.log \
  && ln -sf /dev/stderr /usr/local/openresty/nginx/logs/error.log

LABEL maintainer="Olivier Orabona <olivier.orabona@gmail.com>"

LABEL resty_flavor="${RESTY_FLAVOR}"
LABEL resty_image_base="${RESTY_IMAGE_BASE}"
LABEL resty_image_tag="${RESTY_IMAGE_TAG}"
LABEL resty_version="${RESTY_VERSION}"
LABEL resty_openssl_version="${RESTY_OPENSSL_VERSION}"
LABEL resty_pcre_version="${RESTY_PCRE_VERSION}"
LABEL resty_config_options="${RESTY_CONFIG_OPTIONS}"
LABEL resty_config_options_more="${RESTY_CONFIG_OPTIONS_MORE}"
LABEL resty_config_deps="${_RESTY_CONFIG_DEPS}"
LABEL resty_add_package_builddeps="${RESTY_ADD_PACKAGE_BUILDDEPS}"
LABEL resty_add_package_rundeps="${RESTY_ADD_PACKAGE_RUNDEPS}"
LABEL resty_eval_pre_configure="${RESTY_EVAL_PRE_CONFIGURE}"
LABEL resty_eval_post_make="${RESTY_EVAL_POST_MAKE}"
LABEL luarocks_version="${LUAROCKS_VERSION}"

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT
