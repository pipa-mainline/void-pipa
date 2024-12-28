#!/usr/bin/env bash
./build_packages.sh
sudo ./build_rootfs_base.sh
sudo ./build_rootfs_kde.sh
sudo ./build_rootfs_gnome.sh
