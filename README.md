# Lichee Pi Nano Bootable Linux Image (Buildroot)

![Lichee Pi Nano with LCD screen](licheepi-nano-lcd.jpg)

[Lichee Pi Nano](https://wiki.sipeed.com/soft/Lichee/zh/Nano-Doc-Backup/get_started/first_eye.html) ([English article](https://www.cnx-software.com/2018/08/17/licheepi-nano-cheap-sd-card-sized-linux-board/), [old site](http://nano.lichee.pro/index.html)) is a very small single-board computer that is about the size of an SD card. It can run Linux. There is a good amount of official documentation on the [original manufacturer site](http://nano.lichee.pro/get_started/first_eye.html) (in Chinese, but easily readable thanks to Google Translate). However, the tooling used to build the full card/SPI-Flash images is mostly made up of custom shell scripts, and is not always easy to extend or maintain.

This repository contains a Buildroot-based Linux image build for the Lichee Pi Nano. It compiles a U-Boot image, Linux kernel, the rootfs image and the final partitioned binary image for flashing onto the bootable micro SD card (note: SPI-Flash boot image builds are possible but I did not get a chance to try them yet).

All the custom configuration is packaged as a `BR2_EXTERNAL` Buildroot extension to avoid the need to fork the entire Buildroot repo. You can fork this project or integrate it as a Git subtree to customize your own OS build on top of it as needed.

The build process uses [Docker](Dockerfile) for reproducibility and convenience. If you are an advanced Linux user you can set up your own build on your host machine by running the same commands as [Dockerfile.base].

Explore the configuration and modify it at will: e.g. start with the main Buildroot defconfig file in [configs/licheepi_nano_defconfig](configs/licheepi_nano_defconfig). You will most likely need to update the Linux DTS (device tree) file to match your board usage, for which you can edit [suniv-f1c100s-licheepi-nano-custom.dts](board/licheepi_nano/suniv-f1c100s-licheepi-nano-custom.dts). Sample peripheral descriptions are listed in comments there - uncomment and modify what you need. This custom DTS file includes the original [suniv-f1c100s-licheepi-nano.dts](https://github.com/unframework/linux/blob/nano-5.11/arch/arm/boot/dts/suniv-f1c100s-licheepi-nano.dts) in the kernel tree, so you don't need to fork the kernel or duplicate code to make your local customizations. I may also set up an equivalent customizable U-Boot DTS file in the future.

More customization is available by changing other files in the `board` and `configs` directories, such as the kernel boot command, kernel defconfig and SD image layout. There is also a preconfigured rootfs overlay folder, ready to populate.

This effort heavily borrowed from the work done by the FunKey Zero project: https://github.com/Squonk42/buildroot-licheepi-zero/. The latter targets Lichee Pi Zero, a sibling board to the Nano, but I was able to adapt it for use with Nano, and also converted the content to be a `BR2_EXTERNAL` extension rather than a full Buildroot fork.

Also check out https://github.com/florpor/licheepi-nano: that work was done prior to mine but I somehow didn't find it until later, oops.

## Dependencies

Builds are Docker-based: multi-stage syntax support is needed (available since Docker Engine 17.05 release in 2017). Docker BuildKit support is needed for direct `tar` file output but you can omit that and manually copy `sdcard.img` from the built Docker images.

## Building the Image

The easiest way is using Docker (on Windows/MacOS/Linux). If your Docker is older than v23, ensure that you have [BuildKit enabled](https://docs.docker.com/build/buildkit/#getting-started).

First, clone this repo to your host:

```sh
git clone git@github.com:unframework/licheepi-nano-buildroot.git
```

There are two options available - fast build using the [prepared Docker Hub images](https://hub.docker.com/r/unframework/licheepi-nano-buildroot) or from scratch (takes 1-2 hours or more).

Fast build:

```sh
docker build --output type=tar,dest=- . | (mkdir -p dist && tar x -C dist)
```

The built image will be available in `dist/sdcard.img` - you can write this to your bootable micro SD card (see below).

Full rebuild from scratch:

```sh
docker build -f Dockerfile.base --output type=tar,dest=- . | (mkdir -p dist && tar x -C dist)
```

## Write Bootable Image to SD Card

On Windows, use Rufus or Balena Etcher to write the bootable SD card image (`sdcard.img`). Typical image size is at least 18-20Mb, which should fit on most modern SD cards.

Example command to write image to SD card on Linux host:

```sh
sudo dd if=output/images/sdcard.img of=DEVICE # e.g. /dev/sd?, etc
```

Then, plug in the micro SD card into your Lichee Nano and turn it on!

## Iterating on the Base Image

The "fast build" Docker command allows tweaking config files in `board` and `configs` without having to rebuild everything. First it pulls the [pre-built Docker Hub image](https://hub.docker.com/r/unframework/licheepi-nano-buildroot), re-copies the defconfig and board folder from local workspace into it, and runs the `make` command once again.

Note that certain config file changes will not automatically cause Buildroot to rebuild affected folders. Please see the Buildroot manual sections [Understanding when a full rebuild is necessary](https://buildroot.org/downloads/manual/manual.html#full-rebuild) and [Understanding how to rebuild packages](https://buildroot.org/downloads/manual/manual.html#rebuild-pkg).

It's very convenient to run the intermediate Docker image and inspect the build folder, run `make menuconfig`, etc:

```sh
docker build --target main -t licheepi-nano-tmp
docker run -it licheepi-nano-tmp /bin/bash
```

Just don't forget to e.g. carry out any resulting `.config` file changes back into your source folder as needed.

Once you are happy with your own additions, you can run a full Docker image rebuild and tag the result:

```sh
docker build -f Dockerfile.base --target main -t licheepi-nano-mybase:latest .
```

And then use that image as the base for generating the SD image as well as further config iterations:

```sh
docker build \
  --build-arg="BASE_IMAGE=licheepi-nano-mybase" \
  --output type=tar,dest=- . \
  | (mkdir -p dist && tar x -C dist)
```

For reference, here is how the base image is generated and published (these are the commands I run as the repo maintainer):

```sh
docker build -f Dockerfile.base --target main -t unframework/licheepi-nano-buildroot:$(git rev-parse --short HEAD) .
docker build -f Dockerfile.base --target main -t unframework/licheepi-nano-buildroot:latest .
docker push unframework/licheepi-nano-buildroot:$(git rev-parse --short HEAD)
docker push unframework/licheepi-nano-buildroot:latest
```

## Linux and U-Boot Versions

The built kernel is [a Linux fork based off 5.11](https://github.com/unframework/linux/commits/nano-5.11), with hardware-specific customizations. I have cherry-picked the original customizations from @Lichee-Pi Linux repo [nano-5.2-tf branch](https://github.com/torvalds/linux/compare/master...Lichee-Pi:nano-5.2-tf) and [nano-5.2-flash branch](https://github.com/torvalds/linux/compare/master...Lichee-Pi:nano-5.2-flash) (both based off Linux version 5.2) and added tiny fixes due to newer kernel version.

The built U-Boot is [a fork based off v2021.01](https://github.com/unframework/u-boot/commits/2021.01-f1c100s) with hardware-specific customizations, which I ported over from [the original @Lichee-Pi v2018.01 fork](https://github.com/Lichee-Pi/u-boot/commits/nano-v2018.01) referenced in the docs. By the way, the latter is actually itself a rebase of [an earlier repo branch maintained by @Icenowy](https://github.com/u-boot/u-boot/compare/master...Icenowy:f1c100s-spiflash). Splash screen support is not yet ported.

## LCD Screen Support

By default, the `suniv-f1c100s-licheepi-nano.dts` device tree expects a 800x480 TFT screen to be plugged into the 40-pin flex-PCB connector on the board. You can change this to be a 480x272 TFT screen - simply uncomment the `panel` block at line 14 in [suniv-f1c100s-licheepi-nano-custom.dts](board/licheepi_nano/suniv-f1c100s-licheepi-nano-custom.dts). This will override the `compatible` string for the driver and trigger the lower resolution (see also [original docs](http://nano.lichee.pro/build_sys/devicetree.html#lcd)).
