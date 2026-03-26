# HiBy R3 Pro II Firmware Format Documentation

## Overview
The .upt firmware file is an ISO 9660 disc image containing:
- ota_config.in (version info)
- ota_v0/ (update package directory)

## ISO Structure
```
r3proii.upt (ISO 9660)
├── ota_config.in          # Contains: current_version=0
└── ota_v0/
    ├── ota_update.in      # Image metadata (sizes, MD5s)
    ├── ota_v0.ok          # Sentinel file (must exist)
    ├── ota_md5_xImage.<MD5>                  # xImage chunk manifest
    ├── ota_md5_rootfs.squashfs.<MD5>         # rootfs chunk manifest
    ├── xImage.0000.<MD5>                     # Kernel chunks
    ├── xImage.0001.<MD5>
    ├── ...
    ├── rootfs.squashfs.0000.<ROOTFS_MD5>     # rootfs chunks
    ├── rootfs.squashfs.0001.<CHUNK0_MD5>
    └── ...
```

## Chunk Naming Convention (CRITICAL)
Files follow a chain hash system:
- Chunk 0000: named with OVERALL rootfs MD5
- Chunk 0001: named with MD5 of chunk 0000's content
- Chunk 0002: named with MD5 of chunk 0001's content
- etc.

## Manifest Format
Each manifest file contains one MD5 per line:
- Line 1: MD5 of chunk 0000's content
- Line 2: MD5 of chunk 0001's content
- etc.

## ota_update.in Format
```
ota_version=0

img_type=kernel
img_name=xImage
img_size=<bytes>
img_md5=<overall_xImage_MD5>

img_type=rootfs
img_name=rootfs.squashfs
img_size=<bytes>
img_md5=<overall_rootfs_MD5>
```

## Squashfs Parameters
The rootfs uses these exact parameters:
- Compression: LZO (lzo1x_999 algorithm, level 9)
- Block size: 131072 bytes
- Exportable: yes
- Xattrs: yes (but 0 xattr ids)
- mkfs-time: 2026-01-15 20:45:38
- Chunk size: 520997 bytes

## Partition Layout (NAND MTD)
- mtd5: OTA boot state partition
  - Contains "ota:kernel" or "ota:kernel2"
  - Also stores theme ID at offset 0x20000
- kernel / kernel2: dual kernel partitions
- rootfs / rootfs2: dual rootfs partitions
- rtos: RTOS partition
- userdata: UBIFS partition mounted at /data

## Key Paths
- z:\ = /usr/resource/ (internal resources)
- a:\ = SD card (/data/mnt/sd_0/)
- v0:\ = /data/ (userdata partition)

## Font System
Fonts located at /usr/resource/fonts/:
- default.otf: MiSans-Regular (29601 glyphs, CFF-based, ~6.5MB)
- Korean.ttf: Korean supplementary font
- Thai.ttf: Thai supplementary font (used as fallback for unknown scripts)

## Arabic Font Modification
Arabic support added by merging Noto Naskh Arabic glyphs into Thai.ttf:
- Source: Noto Naskh Arabic Regular (OFL licensed)
- 252 glyphs from Unicode block U+0600-U+06FF
- Must scale glyphs by factor 2.56 (Thai em=2560, Arabic em=1000)
- Thai glyphs preserved, total 453 glyphs in modified Thai.ttf

## Boot Sequence
Init scripts run in this order (from /etc/init.d/):
1. S10mdev - device node creation
2. S11jpeg_display_shell - boot logo display (reads theme from mtd5 offset 0x20000)
3. S11module_driver_default - hardware driver initialization
4. S20urandom - random seed
5. S21mount_ubifs - mounts userdata UBIFS partition at /usr/data/
6. S30dbus - D-Bus system message bus
7. S39_recovery.recovery - checks /data/recovery_all for factory reset trigger
8. S40network - network initialization
9. S43wifi_bcm_init_config - WiFi (Broadcom)
10. S50sys_server - system server
11. S80_bt_init - Bluetooth initialization
12. S92_03_start_music_player - launches hiby_player via hiby_player.sh

## Recovery Mechanism
The device has a built-in factory reset mechanism:
- If /data/recovery_all contains "recovery_all" -> full wipe of /data/*
- If /data/recovery_all contains anything else -> partial wipe (preserves usrlocal_media.db)
- After wipe, device reboots automatically

## OTA Update Scripts
Located at /etc/ota_bin/:
- local_ota_update.sh - main SD card OTA update script
- ota_update_rootfs_squashfs.sh - rootfs flash script (uses nandwrite)
- ota_update_kernel.sh - kernel flash script
- ota_utils.sh - utility functions (MD5, MTD operations)
- ota_local_method.sh - device-specific methods (partition paths, boot device)

## Bluetooth Stack
Based on BlueALSA. Key binaries:
- bluealsa, bluealsa-aplay, bluealsa-cli
- bluetoothctl
- brcm_patchram_plus (Broadcom firmware loader)
- bt_enable.sh, bt_disable, bt_init

## Custom Font Config (SD Card)
The binary supports a custom font config at a:\font\custom_font_config.ini
WARNING: Any content in this file causes hiby_player to crash on this firmware version.
Do not use this feature - it is broken in the current firmware.

## Hardware
- SoC: Ingenic X1600
- DAC: CS43198 (dual)
- WiFi/BT: Broadcom (brcm_patchram_plus)
- Touch: GT9xx
- Display: ST7701 LCD
- Battery gauge: CW2015
- Power management: AXP2101, MP2731

## Notes
- The device uses a dual-boot partition scheme (kernel/kernel2, rootfs/rootfs2)
- The OTA partition (mtd5) tracks which partition set is active
- ADB is present but disabled by default (adbd, adbon, adboff binaries exist)
- The main application binary (hiby_player) is proprietary and closed source
- Kernel source may be available from HiBy under GPL - check github.com/hiby-music
