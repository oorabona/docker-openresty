ARG RESTY_FLAVOR="basic"
ARG RESTY_VERSION="latest"
ARG RESTY_IMAGE_BASE="alpine"
ARG RESTY_IMAGE_TAG="3.13"

FROM oorabona/openresty-${RESTY_FLAVOR}:${RESTY_VERSION}-${RESTY_IMAGE_BASE} AS base

ARG RESTY_FLAVOR="basic"
ARG RESTY_CONFIG_PATH="/usr/local/openresty/nginx/conf"
ARG RESTY_MODSECURITY_VERSION=""

RUN  find /usr/local -exec file {} \; | grep ELF|grep "not stripped"|{ while read l; do file=$(echo $l|cut -d':' -f1); echo "Stripping $file" ; strip --strip-unneeded $file ; done }

COPY conf/ /tmp/conf
COPY helpers/install-${RESTY_FLAVOR} /usr/local/bin/install-openresty

RUN  apk add --no-cache gettext \
  && /usr/local/bin/install-openresty \
  && rm -f /usr/local/bin/install-openresty

FROM ${RESTY_IMAGE_BASE}:${RESTY_IMAGE_TAG}

ARG RESTY_ADD_PACKAGE_RUNDEPS=""

RUN   apk add --no-cache \
      binutils \
      gd \
      geoip \
      libgcc \
      libxslt \
      zlib \
      curl \
      yajl \
      libintl \
      musl \
      outils-md5 \
      perl \
      unzip \
      libmaxminddb \
      ${RESTY_ADD_PACKAGE_RUNDEPS} \
  &&  mkdir -p /var/run/openresty ${RESTY_CONFIG_PATH} \
  &&  echo ok

COPY --from=base /usr/local /usr/local
COPY --from=base ${RESTY_CONFIG_PATH} ${RESTY_CONFIG_PATH}

# Add additional binaries into PATH for convenience
ENV PATH=$PATH:/usr/local/openresty/luajit/bin:/usr/local/openresty/nginx/sbin:/usr/local/openresty/bin

CMD ["/usr/local/openresty/bin/openresty", "-g", "daemon off;"]

EXPOSE 80/tcp 443/tcp

# Use SIGQUIT instead of default SIGTERM to cleanly drain requests
# See https://github.com/openresty/docker-openresty/blob/master/README.md#tips--pitfalls
STOPSIGNAL SIGQUIT
