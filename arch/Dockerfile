# This docker image creates an Arch Linux SD card image with cloud-init
FROM archlinux

# Install required packages
RUN pacman -Sy --noconfirm parted dosfstools xfsprogs

# Create directory we will be working in
RUN mkdir /work
WORKDIR /work

# Build the image
ADD build.sh /usr/bin/build.sh
RUN chmod +x /usr/bin/build.sh

ENTRYPOINT [ "/usr/bin/build.sh" ]