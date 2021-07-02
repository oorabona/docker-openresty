# docker-openresty - OpenResty flavors for Docker

[![Main CI](https://github.com/oorabona/docker-openresty/actions/workflows/main-ci.yml/badge.svg)](https://github.com/oorabona/docker-openresty/actions/workflows/main-ci.yml)

## TL;DR

The following "flavors" are customized builds of OpenResty source code :

Standard (for dev/qa)
---------------------

| flavor | build status | docker hub |
|-|-|-|
| Basic ("bare") OpenResty | [![Main CI](https://github.com/oorabona/docker-openresty/actions/workflows/main-ci.yml/badge.svg)](https://github.com/oorabona/docker-openresty/actions/workflows/main-ci.yml) | [![OpenResty Basic version](https://img.shields.io/docker/v/oorabona/openresty-basic/latest)](https://hub.docker.com/r/oorabona/openresty-basic)[![OpenResty Basic pulls](https://img.shields.io/docker/pulls/oorabona/openresty-basic)](https://hub.docker.com/r/oorabona/openresty-basic)
| OpenResty with HTTP Connect | [![Main CI](https://github.com/oorabona/docker-openresty/actions/workflows/main-ci.yml/badge.svg)](https://github.com/oorabona/docker-openresty/actions/workflows/main-ci.yml) | [![OpenResty Connect version](https://img.shields.io/docker/v/oorabona/openresty-connect/latest)](https://hub.docker.com/r/oorabona/openresty-connect)[![OpenResty Connect pulls](https://img.shields.io/docker/pulls/oorabona/openresty-connect)](https://hub.docker.com/r/oorabona/openresty-connect)
| OpenResty with ModSecurity | [![Main CI](https://github.com/oorabona/docker-openresty/actions/workflows/main-ci.yml/badge.svg)](https://github.com/oorabona/docker-openresty/actions/workflows/main-ci.yml) | [![OpenResty ModSecurity version](https://img.shields.io/docker/v/oorabona/openresty-modsecurity/latest)](https://hub.docker.com/r/oorabona/openresty-modsecurity)[![OpenResty ModSecurity pulls](https://img.shields.io/docker/pulls/oorabona/openresty-modsecurity)](https://hub.docker.com/r/oorabona/openresty-modsecurity)

"Hardened" (production)
-----------------------

- Basic ("bare") OpenResty [![OpenResty Basic version](https://img.shields.io/docker/v/oorabona/openresty-hardened-basic/latest)](https://hub.docker.com/r/oorabona/openresty-hardened-basic)[![OpenResty Basic pulls](https://img.shields.io/docker/pulls/oorabona/openresty-hardened-basic)](https://hub.docker.com/r/oorabona/openresty-hardened-basic)

- OpenResty with HTTP Connect [![OpenResty Connect version](https://img.shields.io/docker/v/oorabona/openresty-hardened-connect/latest)](https://hub.docker.com/r/oorabona/openresty-connect)[![OpenResty Connect pulls](https://img.shields.io/docker/pulls/oorabona/openresty-hardened-connect)](https://hub.docker.com/r/oorabona/openresty-hardened-connect)

- OpenResty with ModSecurity [![OpenResty ModSecurity version](https://img.shields.io/docker/v/oorabona/openresty-hardened-modsecurity/latest)](https://hub.docker.com/r/oorabona/openresty-hardened-modsecurity)[![OpenResty ModSecurity pulls](https://img.shields.io/docker/pulls/oorabona/openresty-hardened-modsecurity)](https://hub.docker.com/r/oorabona/openresty-hardened-modsecurity)

All these flavors are built with multi-architecture manifests.

The following platforms are built :
- linux/amd64
- linux/arm/v7

But of course others could be added as well, let me know of any interest in adding new platforms.

Releases are tagged with `<openresty-version>-<base-os>`

For now, only `alpine` is used as a base OS to build OpenResty on.
The latest version is always tagged with `latest-<base-os>`.

> In the event other images are built from a different base image than `alpine`, the `latest` tag will always point to `latest-alpine`.


Table of Contents
=================

- [Description](#description)
- [Usage](#usage)
  * [Running locally](#running-locally)
  * [Using Kubernetes](#using-kubernetes)
- [Images](#images)
  * [Main differences with the upstream repository](#main-differences-with-the-upstream-repository)
  * [About other packaging out there](#about-other-packaging-out-there)
  * [Technical stuff](#technical-stuff)
- [Software Installed](#software-installed)
  * [Runtime Packages](#runtime-packages)
  * [OpenResty / NGinx additional libraries](#openresty---nginx-additional-libraries)
  * [Possible future additions :](#possible-future-additions--)
- [Nginx Config Files](#nginx-config-files)
- [Production Hardened Versions](#production-hardened-versions)
- [OPM](#opm)
- [LuaRocks](#luarocks)
- [Image Labels](#image-labels)
- [Docker ENTRYPOINT & CMD](#docker-entrypoint---cmd)
- [Building from source](#building-from-source)
- [Continuous Integration](#continuous-integration)
- [Continuous Deployment](#continuous-deployment)
- [Feedback & Bug Reports](#feedback---bug-reports)
- [Other Documentation](#other-documentation)
- [Copyright & License](#copyright---license)

Description
===========

[OpenResty](https://openresty.org) is an awesome integration work of Nginx with the power of the scripting language [Lua](https://lua.org) provides. There is already an official [Docker](https://docs.docker.com) repository for the containerized packages named [docker-openresty](https://github.com/openresty/docker-openresty).

Kudos go to all the teams who contribute to this work. :+1:

Although you will find some similarities with the former repository, this project is meant to go further with more integrated libraries loaded in.

Indeed [NGiNX](https://nginx.com) has an ecosystem of external libraries and bindings which would be nice to have in OpenResty.

Therefore this repository goal is to properly package these to the world of OpenResty.

Usage
=====

Your habits (should!) remain unchanged :wink:

Running locally
---------------

```sh
# The latest version for a distribution
$ docker run [options] oorabona/openresty-<FLAVOR>:alpine
# A specific version with its distro
$ docker run [options] oorabona/openresty-<FLAVOR>:1.19.3.2-alpine
# The hardened version
$ docker run [options] oorabona/openresty-hardened-<FLAVOR>:alpine
```

Using Kubernetes
----------------

> TODO

[Back to TOC](#table-of-contents)

Images
======

Like the official [OpenResty official Docker repository](https://github.com/openresty/docker-openresty), the underlying base system of choice is the `Alpine` image, although a `Debian` **Buster** is under work.

OpenResty software, and what is directly involved in its compilation (OpenSSL, Luarocks, etc.) are built from their source.

Main differences with the upstream repository
---------------------------------------------

* At the moment there is no installation of binary packages, given that most of the software do not have repository binaries (partly because it is kind of bleeding edge), it would be eventually less adaptable and quite complex (if even possible) to have it installed by a single `apt` or `apk` command.

* For numerous reasons, the main goal when building these images is to minimize their size. This is not an easy task and at the moment the `Alpine` based image is by far the smallest image.

* Therefore there is no `-fat` version at all. If you need to install additional software, feel free to use these images as *base* in your `FROM` directives.

* Last difference, the PRE / POST evaluated `ARG`uments, which are later `eval`uated in `RUN` commands have been removed. Again if you need something specific, either derive from these images, or use them in a `COPY --from` for example.

About other packaging out there
-------------------------------

* [bunkerized-nginx](https://github.com/bunkerity/bunkerized-nginx) has more scripts and is more integrated with auto SSL with Let's Encrypt, and lots of other features and a configuration system of its own.

Again, all of these integrations can be done by deriving from this work. Everything related to configuration handling and such is somewhat one's own recipe, whether Swarm or Kubernetes based, etc. So basically you are more than welcome to derive from these images and build your own system from it!

> Feel free to point out other related packages missing from this list !

Technical stuff
---------------

* By convention, symlinks are created to point `/usr/local/openresty/nginx/logs/access.log` and `error.log` to `/dev/stdout` and `/dev/stderr` respectively, so that Docker logging works correctly.  If you change the log paths in your `nginx.conf`, you should symlink those paths as well.

* The `pid` is by default pointing to `/usr/local/openresty/nginx/logs/nginx.pid`, although it is not used since these images run `openresty` binary straight away. For more details, please refer to [Docker ENTRYPOINT & CMD](#docker-entrypoint--cmd)

* The `SIGQUIT` signal will be sent to nginx to stop this container, to give it an opportunity to stop gracefully (i.e, finish processing active connections).  The Docker default is `SIGTERM`, which immediately terminates active connections.   Note that if your configuration listens on UNIX domain sockets, this means that you'll need to manually remove the socket file upon shutdown, due to [nginx bug #753](https://trac.nginx.org/nginx/ticket/753).

* A single Dockerfile handles the build of all flavors for a specific distribution. This is done thanks to multistage Dockerfile which appeared around 18.x version of Docker. Please use a recent version if you want to build these images.

* These images are built for multi architecture. At the moment only `linux/amd64` and `linux/arm/v7` (i.e. Raspberry Pi) architectures are built. Other architectures could also be built (as long as QEMU supports) if requested.

* Building is parallelized as much as possible. The `RESTY_J` `ARG`ument is set to **4** CPU by default, but of course this is computed automagically from the `nproc` program called by the [build](build) script.

> For details on how to build these images, please go to [Building from source](#building-from-source)

[Back to TOC](#table-of-contents)

Software Installed
==================

Runtime Packages
----------------

The following packages are added to the base `Alpine` image:

* git
* build-base
* gd
* geoip
* libgcc
* libxslt
* zlib
* curl
* yajl
* libintl
* make
* musl
* outils-md5
* perl
* unzip
* libmaxminddb

> `libmaxminddb` is installed in all flavors because it is the most widespread GeoIP library out there. According to some comparison articles (for reference [here](https://underconstructionpage.com/free-paid-geoip-services/) and [here](https://geekflare.com/geolocation-ip-api/)) there is not a single point of truth about that. Feel free to submit issues / PR if you want other GeoIP providers being enlisted.

OpenResty / NGinx additional libraries
--------------------------------------

In all flavors, a common set of opinionated libraries are automatically built, whether as dynamic modules or as static modules:

| Module name | Description | Dynamic module | Static module |
|-|-|-|-|
| http_addition_module | part of base source | | :heavy_check_mark: |
| http_auth_request_module | part of base source | | :heavy_check_mark: |
| http_dav_module | part of base source | | :heavy_check_mark: |
| http_flv_module | part of base source | | :heavy_check_mark: |
| http_geoip_module | part of base source | :heavy_check_mark: | |
| http_gunzip_module | part of base source | | :heavy_check_mark: |
| http_gzip_static_module | part of base source | | :heavy_check_mark: |
| http_image_filter_module | part of base source | :heavy_check_mark: | |
| http_mp4_module | part of base source | | :heavy_check_mark: |
| http_random_index_module | part of base source | | :heavy_check_mark: |
| http_realip_module | part of base source | | :heavy_check_mark: |
| http_secure_link_module | part of base source | | :heavy_check_mark: |
| http_slice_module | part of base source | | :heavy_check_mark: |
| http_ssl_module | part of base source | | :heavy_check_mark: |
| http_stub_status_module | part of base source | | :heavy_check_mark: |
| http_sub_module | part of base source | | :heavy_check_mark: |
| http_v2_module | part of base source | | :heavy_check_mark: |
| http_xslt_module | part of base source | :heavy_check_mark: | |
| mail_ssl_module | part of base source | | :heavy_check_mark: |
| stream_ssl_module | part of base source | | :heavy_check_mark: |
| stream_realip_module | part of base source | | :heavy_check_mark: |
| [ngx_brotli](https://github.com/google/ngx_brotli) | Implements Google Brotli compression scheme | | :heavy_check_mark: |
| [ngx_http_geoip2_module](https://github.com/leev/ngx_http_geoip2_module) | Implements v2 of MaxMind GeoIP | :heavy_check_mark: | |

Possible future additions :
---------------------------

* https://github.com/ioppermann/modjpeg-nginx
* https://engineering.fb.com/2016/08/31/core-data/smaller-and-faster-data-compression-with-zstandard/
* https://github.com/slact/nchan

[Back to TOC](#table-of-contents)

Nginx Config Files
==================

By default no change is made to the original OpenResty configuration files. They lie in their former directory (namely `/usr/local/openresty/nginx/conf`).

Only for [Production hardened versions](#production-hardened-versions) would the basic configuration be replaced with an opinionated set of configuration files.

Eventually you can either bind-mount the volume with :

```
docker run -v /my/custom/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf oorabona/openresty-${flavor}:latest-alpine
```

Or completely replace the whole directory :

```
docker run -v /my/custom/nginx/conf:/usr/local/openresty/nginx/conf oorabona/openresty-${flavor}:latest-alpine
```

Of course you can also derive from these images to tweak the configuration.

```Dockerfile
FROM oorabona/openresty-modsecurity:latest-alpine

COPY /my/conf/for/modsecurity /to/place/here
...
```

If you are running on an `SELinux` host (e.g. CentOS), you may need to append `:Z` to your [volume bind-mount argument](https://docs.docker.com/storage/bind-mounts/#configure-the-selinux-label):

E.g:

```
docker run -v /my/custom/nginx/conf:/usr/local/openresty/nginx/conf:Z oorabona/openresty-${flavor}:latest-alpine
```

[Back to TOC](#table-of-contents)

Production Hardened Versions
============================

You can have a look at these configuration files [here](conf) and adjust them to fit your needs.

Production images replace the default `nginx.conf` and all references to NGiNX configuration files are relative to the base directory.

Base directory is by default `/usr/local/openresty/nginx/conf` but can be changed in the [production vars](conf/production.vars) file.

You then just need to change only **enabled sites** :

```
docker run -v /my/custom/sites/enabled/:/usr/local/openresty/nginx/conf/sites-enabled oorabona/openresty-${flavor}:latest-alpine
```

Temporary directories such as `client_body_temp_path` are stored in `/var/run/openresty/`.  You may consider mounting that volume, rather than writing to a container-local directory.

> Hardened versions are built on the latest image version

What is different in these versions ?
-------------------------------------

Mostly a stable, state-of-the-art (if not, please submit issue/PR) configuration files to use as a base for your projects.

Of course not every single configuration will be implemented here, only fundamental (i.e. mandatory) setup, amongst which:

- Typical configuration for each flavor
- SSL/HSTS/CSP/etc.
- Security best practices for nginx
- Security best practices for Docker

[Back to TOC](#table-of-contents)

OPM
===

Starting at version 1.11.2.2, OpenResty for Linux includes a [package manager called `opm`](https://github.com/openresty/opm#readme), which can be found at `/usr/local/openresty/bin/opm`.

This package is installed in every distribution (OS) and is meant to provide a ground for derived images to integrate extra packages. Feel free to use it and then remove if needed to both size and security reasons.

For that, multi stage `Dockerfile`s will help.

```Dockerfile
RUN /usr/local/openresty/bin/opm install <package>
```

[Back to TOC](#table-of-contents)

LuaRocks
========

Similarly [LuaRocks](https://luarocks.org) is installed in every distribution (OS) and has a broader package repository than [OPM](#opm).

Its binary can be found in `/usr/local/bin/luarocks`.

For instance you could, in a multi stage `Dockerfile` have this line :

```Dockerfile
RUN /usr/local/bin/luarocks install <rock>
```

[Back to TOC](#table-of-contents)

Image Labels
============

These `LABEL`s are set in each image built. Most of them are common with the official OpenResty Docker repository. Some of them have been removed.

| Label Name                   | Description             |
:----------------------------- |:----------------------- |
|`maintainer`                  | Maintainer of the image |
|`resty_flavor`                | buildarg `RESTY_FLAVOR` |
|`resty_add_package_builddeps` | buildarg `RESTY_ADD_PACKAGE_BUILDDEPS` |
|`resty_add_package_rundeps`   | buildarg `RESTY_ADD_PACKAGE_RUNDEPS` |
|`resty_config_deps`           | buildarg `_RESTY_CONFIG_DEPS` (internal) |
|`resty_config_options`        | buildarg `RESTY_CONFIG_OPTIONS`  |
|`resty_config_options_more`   | buildarg `RESTY_CONFIG_OPTIONS_MORE`  |
|`resty_image_base`            | Name of the base image to build from, buildarg  `RESTY_IMAGE_BASE` |
|`resty_image_tag`             | Tag of the base image to build from, buildarg `RESTY_IMAGE_TAG` |
|`resty_luajit_options`        | buildarg `RESTY_LUAJIT_OPTIONS` |
|`resty_luarocks_version`      | buildarg `RESTY_LUAROCKS_VERSION` |
|`resty_openssl_version`       | buildarg `RESTY_OPENSSL_VERSION` |
|`resty_openssl_patch_version` | buildarg `RESTY_OPENSSL_PATCH_VERSION` |
|`resty_openssl_url_base`      | buildarg `RESTY_OPENSSL_URL_BASE` |
|`resty_pcre_version`          | buildarg `RESTY_PCRE_VERSION`  |
|`resty_version`               | buildarg `RESTY_VERSION`  |

[Back to TOC](#table-of-contents)

Docker ENTRYPOINT & CMD
=======================

The `-g "daemon off;"` directive is used in the Dockerfile `CMD` to keep the Nginx daemon running after container creation. If this directive is added to the nginx.conf, then the `docker run` should explicitly invoke `openresty`:

```
docker run [options] oorabona/openresty-<FLAVOR>:alpine openresty
```

Invoke another CMD, for example the `resty` utility, like so:
```
docker run [options] oorabona/openresty-<FLAVOR>:alpine resty [script.lua]
```

Since this is way easier to operate and there is no need to wrap commands around a script, no `ENTRYPOINT` is needed.

[Back to TOC](#table-of-contents)

Building from source
====================

If you want to build yourself these OpenResty flavors, you just need to `git clone` this repository and use the `build` script at its root.

```
git clone https://github.com/oorabona/docker-openresty.git
cd docker-openresty
./build
```

It comes with little help on its own :

```sh
$ ./build
build <OSes> [flavors] [version] [platforms]

OSes, flavors and platforms must be separated by commas.
If you want to specify version and/or platforms and you want to build all flavors, use 'all'.
If not specified, default version is 'latest'.
If not specified, all flavors for a specific OS are built.
If not specified, linux/arm/v7 and linux/amd64 are built, 'all' is accepted.
```

So you can build either all flavors for a specific *base* OS or a specific version of a specific flavor on a specific platform with the same build tool :wink:

> **NOTES**
> * Flavors are derived from the number of **shell** scripts present in the directory of the base OS. The default is to build all of them.
> * The default value for `version` is `latest`. In which case both the version number and `latest` tag will be pushed.
> * As for now, `platforms` are only `linux/arm/v7` (Raspberry Pi) and `linux/amd64`. Other may come in the future but since this is cross compiling, it takes way more time.

```sh
# Builds on Alpine Linux, all flavors, latest version, default platforms
$ ./build alpine
# Builds on Alpine Linux, ModSecurity only, latest version, Linux AMD64 only
$ ./build alpine modsecurity latest linux/amd64
# Builds on Alpine Linux, all flavors, on 1.19.3.1 version, default platforms
$ ./build alpine all 1.19.3.1
# Builds on Alpine Linux, all flavors, latest version, all platforms (supported by QEMU)
$ ./build alpine all latest all
```

Building hardened versions
--------------------------

If you want to build the *hardened* images, use the environment variable `HARDENED` and set it to `1` :

```sh
# Enable hardened image build
$ export HARDENED=1
# Builds on hardened Alpine Linux, all flavors, latest version, default platforms
$ ./build alpine
# Builds on hardened Alpine Linux, ModSecurity only, latest version, Linux AMD64 only
$ ./build alpine modsecurity latest linux/amd64
# Builds on hardened Alpine Linux, all flavors, on 1.19.3.1 version, default platforms
$ ./build alpine all 1.19.3.1
# Builds on hardened Alpine Linux, all flavors, latest version, all platforms (supported by QEMU)
$ ./build alpine all latest all
```

[Back to TOC](#table-of-contents)

Continuous Integration
======================

At the moment, the following pipelines are set up :

* [Main CI](https://github.com/oorabona/docker-openresty/actions/workflows/main-ci.yml)

To do :

* Automatic build on new version upstream

[Back to TOC](#table-of-contents)

Continuous Deployment
=====================

> TODO

[Back to TOC](#table-of-contents)

Feedback & Bug Reports
======================

You're very welcome to report bugs and give feedback as GitHub Issues:

https://github.com/oorabona/docker-openresty/issues

[Back to TOC](#table-of-contents)


Other Documentation
===================

* [CHANGELOG](CHANGELOG.md)

[Back to TOC](#table-of-contents)


Copyright & License
===================

This work is licensed under MIT [license](LICENSE).

Part of it has been inspired by the work done by Evan Wies in this [repository](https://github.com/openresty/docker-openresty).

Kudos go to the team of great people at OpenResty.

[Back to TOC](#table-of-contents)
