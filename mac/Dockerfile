# Containerlab helper image for restricted macOS Docker Desktop environments.
#
# Base image:
#   DoD Iron Bank UBI 9
#
# Build context must contain a Linux containerlab binary matching the
# Docker Desktop server architecture:
#
#   mac/
#   ├── Dockerfile
#   └── containerlab
#
# Example:
#   docker build -t avd-containerlab-mac:0.79.0 ./mac

FROM registry1.dso.mil/ironbank/redhat/ubi/ubi9:9.8

USER 0

COPY containerlab /usr/local/bin/containerlab

# Containerlab's sudo-less Linux installation uses the SUID bit.
RUN chmod 4755 /usr/local/bin/containerlab

WORKDIR /workspace

ENTRYPOINT []
CMD ["/bin/bash"]
