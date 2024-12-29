#!/usr/bin/env bash
source ./env.sh

if [ ! -d $WORKDIR ]; then
        mkdir $WORKDIR
fi

if [ ! -d $OUTDIR ]; then
	mkdir $OUTDIR
fi

pushd $WORKDIR

if [ ! -f "linux.img" ]; then
	echo "You need to build base image first"
    exit 1
fi

# HACK
modprobe binfmt_misc
mount binfmt_misc /proc/sys/fs/binfmt_misc -t binfmt_misc
echo ':aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/qemu-aarch64-static:' | tee /proc/sys/fs/binfmt_misc/register
echo ':aarch64ld:M::\x7fELF\x02\x01\x01\x03\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/qemu-aarch64-static:' | tee /proc/sys/fs/binfmt_misc/register
cp linux.img linux_kde.img

if [ ! -d "rootfs_mountpoint" ]; then
	mkdir rootfs_mountpoint
fi

e2fsck -f linux_kde.img
resize2fs linux_kde.img 8G
mount linux_kde.img rootfs_mountpoint

mount --bind /dev rootfs_mountpoint/dev
mount --bind /dev/pts rootfs_mountpoint/dev/pts
mount --bind /proc rootfs_mountpoint/proc
mount --bind /sys rootfs_mountpoint/sys

install -m755 qemu-aarch64-static rootfs_mountpoint/

if [ "$USE_CACHE_REPO" -eq 1 ]; then
	echo "repository=$CACHE_REPO" > rootfs_mountpoint/etc/xbps.d/00-repository-main.conf
fi


chroot rootfs_mountpoint xbps-install -Suy kde-plasma kde-baseapps sddm xorg mesa-freedreno-dri qt6-virtualkeyboard pipewire bluez libspa-bluetooth xdg-desktop-portal-kde

# SDDM Configuration
chroot rootfs_mountpoint touch /etc/sddm.conf
chroot rootfs_mountpoint mkdir /etc/sddm.conf.d/
cp ../config/kde/sddm/10-wayland.conf rootfs_mountpoint/etc/sddm.conf.d/
cp ../config/kde/sddm/50-theme.conf rootfs_mountpoint/etc/sddm.conf.d/

# Pipewire
chroot rootfs_mountpoint mkdir -pv /etc/pipewire/pipewire.conf.d
chroot rootfs_mountpoint /bin/bash -c "ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/"
chroot rootfs_mountpoint /bin/bash -c "ln -s /usr/share/examples/pipewire/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d/"

# Enable services
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/sddm /etc/runit/runsvdir/default"
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/bluetoothd /etc/runit/runsvdir/default"
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/pipa-bt-quirk /etc/runit/runsvdir/default"

chroot rootfs_mountpoint /sbin/usermod -aG audio,video,bluetooth user

if [ "$USE_CACHE_REPO" -eq 1 ]; then
	echo "repository=$REPO" > rootfs_mountpoint/etc/xbps.d/00-repository-main.conf
fi

rm rootfs_mountpoint/qemu-aarch64-static
umount -R rootfs_mountpoint
img2simg linux_kde.img ../$OUTDIR/void_kde.img
chown 1000:1000 ../$OUTDIR/void_kde.img
