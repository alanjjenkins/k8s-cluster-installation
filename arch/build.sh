#!/bin/bash
set -euo pipefail

# Partition sizes
BOOT_SIZE_MB=300
ROOT_SIZE_MB=700

# Create a file to partition to create the image
IMG_PATH="/work/arch-aarch64-image.img"
test -f "$IMG_PATH" || dd if=/dev/zero of="$IMG_PATH" bs=1M count=$(( ("$BOOT_SIZE_MB" * 1024 * 1024) + ("$ROOT_SIZE_MB" * 1024 * 1024) ))


# Partition the image
parted -s "$IMG_PATH" "mklabel msdos"
parted --align optimal -s "$IMG_PATH" "mkpart primary fat32 2048s $((BOOT_SIZE_MB + 1))M"
parted --align optimal -s "$IMG_PATH" "mkpart primary xfs $((BOOT_SIZE_MB + 2))M 100%"
parted -s "$IMG_PATH" "toggle 1 boot"

# Get the offsets to mount
PARTITION_OFFSETS=$(parted -m "$IMG_PATH" "unit B" "print")
BOOT_OFFSET=$(echo "$PARTITION_OFFSETS" | grep -E "^1" | cut -d ':' -f 2 | sed 's/B//')
ROOT_OFFSET=$(echo "$PARTITION_OFFSETS" | grep -E "^2" | cut -d ':' -f 2 | sed 's/B//')

echo "$ROOT_OFFSET"
echo "$BOOT_OFFSET"

# Setup loopback devices
BOOT_LBDEV=$(losetup -o "$BOOT_OFFSET" --sizelimit $(("$ROOT_OFFSET" - "$BOOT_OFFSET"))  --find --show "$IMG_PATH")
ROOT_LBDEV=$(losetup -o "$ROOT_OFFSET" --sizelimit $((100 * 1024 * 1024)) --find --show "$IMG_PATH")

echo "$ROOT_LBDEV"
echo "$BOOT_LBDEV"

# Format partitions
mkfs.vfat -n "BOOT" -F32 "$BOOT_LBDEV"
mkfs.xfs -f -L "ROOT" "$ROOT_LBDEV"

# mount partitions
mount -o loop,offset="$ROOT_OFFSET" "$IMG_PATH" /mnt/
mkdir /mnt/boot
mount -o loop,offset="$BOOT_OFFSET" "$IMG_PATH" /mnt/boot

# Download the Arch aarch64 base
ARCH_BASE_TAR_PATH="/work/arch-aarch64.tar.gz"
test -f "$ARCH_BASE_TAR_PATH" || curl -L 'http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz' -o "$ARCH_BASE_TAR_PATH"

tar xvpf "$ARCH_BASE_TAR_PATH" -C /mnt/

# Unmount loopback devices
umount -R /mnt

# Delete loopback devices
losetup -d "$BOOT_LBDEV"
losetup -d "$ROOT_LBDEV"
