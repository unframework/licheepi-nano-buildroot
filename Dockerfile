ARG BASE_VERSION=latest

FROM unframework/licheepi-nano-buildroot:$BASE_VERSION AS local

# copy newest version of local files
WORKDIR /root/licheepi-nano
COPY board/ board/
COPY configs/ configs/
COPY \
    Config.in \
    external.desc \
    external.mk \
    ./

# rebuild
WORKDIR /root/buildroot
RUN BR2_EXTERNAL=/root/licheepi-nano make licheepi_nano_defconfig
RUN cd output/build/linux-custom/ && rm .stamp_built .stamp_*_installed
RUN make

# expose built image files in standalone root folder
FROM scratch AS localout
COPY --from=local /root/buildroot/output/images/ .
