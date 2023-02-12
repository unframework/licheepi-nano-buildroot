FROM ubuntu:18.04 AS base

# Buildroot release version
ARG BUILDROOT_RELEASE=2020.02

ENV DEBIAN_FRONTEND=noninteractive

# cache apt-get update results
RUN apt-get update

# install build prerequisites
RUN apt-get install -qy \
    bc \
    bison \
    build-essential \
    bzr \
    chrpath \
    cpio \
    cvs \
    devscripts \
    diffstat \
    fakeroot \
    flex \
    gawk \
    git \
    libncurses5-dev \
    libssl-dev \
    locales \
    python3-dev \
    python3-distutils \
    rsync \
    subversion \
    swig \
    texinfo \
    unzip \
    wget \
    whiptail

# external toolchain needs this
RUN update-locale LC_ALL=C

# get Buildroot image
WORKDIR /root/buildroot
RUN wget -qO- http://buildroot.org/downloads/buildroot-${BUILDROOT_RELEASE}.tar.gz | tar --strip-components=1 -xz

# build the cross-compilation toolchain as a separate cacheable image
FROM base AS sdk

# configure a skeleton setup for `make sdk` only at first
# (we take special care to not include other unrelated config files)
WORKDIR /root/licheepi-nano-sdk
RUN echo 'name: LICHEEPI_NANO_SDK' >> external.desc
RUN echo 'desc: LicheePi Nano SDK only' >> external.desc
RUN touch external.mk Config.in
COPY configs/licheepi_nano_sdk_defconfig configs/

# compile the SDK (this takes a while!)
WORKDIR /root/buildroot
RUN BR2_EXTERNAL=/root/licheepi-nano-sdk make licheepi_nano_sdk_defconfig

RUN make sdk

# start main build using the generated toolchain bundle
FROM base AS main

# copy over the SDK tarball (keeping the name)
COPY --from=sdk /root/buildroot/output/images/arm-buildroot-linux-gnueabi_sdk-buildroot.tar.gz /root/

# copy over the main config
WORKDIR /root/licheepi-nano
COPY board/ board/
COPY configs/ configs/
COPY \
    Config.in \
    external.desc \
    external.mk \
    ./

# set up the defconfig
WORKDIR /root/buildroot
RUN BR2_EXTERNAL=/root/licheepi-nano make licheepi_nano_defconfig

# prep the toolchain from the tarball
RUN make toolchain

# prepare for builds (broken out separately to cache more granularly)
RUN make linux-depends
RUN make uboot-depends
