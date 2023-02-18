FROM unframework/licheepi-nano-buildroot AS local

# expose built image files in standalone root folder
FROM scratch AS localout
COPY --from=local /root/buildroot/output/images/ .
