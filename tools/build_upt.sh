#!/bin/bash
# HiBy R3 Pro II Custom Firmware Builder
# Tested on firmware version: current_version=0 (Jan 2026)
# Author: [your name]
# 
# Requirements: mksquashfs, xorriso, fontforge, python3-fontforge
#
# Usage: ./build_upt.sh <path_to_stock_upt> <output_upt>

STOCK_UPT="$1"
OUTPUT_UPT="${2:-r3proii-custom.upt}"
WORKDIR="$(mktemp -d)"

echo "Working directory: $WORKDIR"

# Step 1 - Extract stock firmware
sudo mkdir -p /mnt/upt
sudo mount -o loop,ro "$STOCK_UPT" /mnt/upt
cat $(ls /mnt/upt/ota_v0/rootfs.squashfs.*.* | sort) > "$WORKDIR/stock_rootfs.squashfs"
STOCK_MD5=$(md5sum "$WORKDIR/stock_rootfs.squashfs" | awk '{print $1}')
echo "Stock rootfs MD5: $STOCK_MD5"
cp /mnt/upt/ota_config.in "$WORKDIR/"
cp -r /mnt/upt/ota_v0 "$WORKDIR/ota_v0_stock"
sudo umount /mnt/upt

# Step 2 - Extract rootfs
sudo unsquashfs -d "$WORKDIR/squashfs-root" "$WORKDIR/stock_rootfs.squashfs"

# Step 3 - Apply Arabic font modification
# (font merge script goes here)

# Step 4 - Repack
sudo mksquashfs "$WORKDIR/squashfs-root" "$WORKDIR/new_rootfs.squashfs" \
  -comp lzo -Xalgorithm lzo1x_999 -Xcompression-level 9 \
  -b 131072 -noappend -no-progress \
  -mkfs-time "2026-01-15 20:45:38"

NEW_MD5=$(md5sum "$WORKDIR/new_rootfs.squashfs" | awk '{print $1}')
NEW_SIZE=$(stat -c%s "$WORKDIR/new_rootfs.squashfs")

# Step 5 - Build chunks and upt
# (full build process goes here)

echo "Built: $OUTPUT_UPT"
