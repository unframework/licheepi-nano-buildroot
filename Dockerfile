FROM ubuntu:18.04

# Buildroot release version
ARG BUILDROOT_RELEASE=2020.02

ENV DEBIAN_FRONTEND=noninteractive

# cache apt-get update results
RUN apt-get update

# install build prerequisites
RUN apt-get install -qy \
    bc \
    build-essential \
    bzr \
    chrpath \
    cpio \
    cvs \
    devscripts \
    diffstat \
    fakeroot \
    gawk \
    git \
    libncurses5-dev \
    libssl-dev \
    locales \
    mercurial \
    python3-dev \
    python3-distutils \
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

# @todo more
RUN ["/bin/bash"]
