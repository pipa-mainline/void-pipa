#!/usr/bin/env bash
ROOTFS_URI="https://repo-fastly.voidlinux.org/live/current/void-aarch64-ROOTFS-20240314.tar.xz"
QEMU_URI="wget https://github.com/multiarch/qemu-user-static/releases/download/v7.2.0-1/qemu-aarch64-static"
XBPS_URI="https://repo-fastly.voidlinux.org/static/xbps-static-latest.x86_64-musl.tar.xz"
REPO="https://repo-fastly.voidlinux.org/current/aarch64"
USE_CACHE_REPO=0
CACHE_REPO="http://192.168.1.135:8080/current/aarch64"
PACKAGES="pipa-metapkg"
WORKDIR="workdir"
OUTDIR="out"
