#!/usr/bin/env bash


source ./env.sh

if [ ! -d $WORKDIR ]; then
	mkdir $WORKDIR
fi

pushd $WORKDIR

if [ ! -f "rootfs.tar.xz" ]; then
    wget $ROOTFS_URI -O rootfs.tar.xz
fi

if [ ! -f "qemu-aarch64-static" ]; then
    wget $QEMU_URI
fi

# HACK
modprobe binfmt_misc
mount binfmt_misc /proc/sys/fs/binfmt_misc -t binfmt_misc
echo ':aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/qemu-aarch64-static:' | tee /proc/sys/fs/binfmt_misc/register
echo ':aarch64ld:M::\x7fELF\x02\x01\x01\x03\x00\x00\x00\x00\x00\x00\x00\x00\x03\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/qemu-aarch64-static:' | tee /proc/sys/fs/binfmt_misc/register

truncate -s 4G linux.img
mkfs.ext4 linux.img

if [ ! -d "rootfs_mountpoint" ]; then
	mkdir rootfs_mountpoint
fi

mount linux.img rootfs_mountpoint

tar xvf rootfs.tar.xz -C rootfs_mountpoint

install -m755 qemu-aarch64-static rootfs_mountpoint/

mount --bind /dev rootfs_mountpoint/dev
mount --bind /dev/pts rootfs_mountpoint/dev/pts
mount --bind /proc rootfs_mountpoint/proc
mount --bind /sys rootfs_mountpoint/sys

echo "xiaomi-pipa" > rootfs_mountpoint/etc/hostname
echo "repository=$REPO" > rootfs_mountpoint/etc/xbps.d/00-repository-main.conf
uuid=$(blkid -o value linux.img | head -n 1)
echo "UUID=$uuid / ext4 defaults 0 0" >> rootfs_mountpoint/etc/fstab
echo "nameserver 1.1.1.1" > rootfs_mountpoint/etc/resolv.conf
echo "root=UUID=$uuid" > rootfs_mountpoint/etc/cmdline

chroot rootfs_mountpoint useradd -m -g users -G wheel user

# HACK: chpasswd doesn't really work for some reason
chroot rootfs_mountpoint bash -c "passwd root << EOD
pipathebest
pipathebest
EOD"
chroot rootfs_mountpoint bash -c "passwd user << EOD
123
123
EOD"

echo "%wheel ALL=(ALL:ALL) ALL" > rootfs_mountpoint/etc/sudoers.d/wheel

chroot rootfs_mountpoint xbps-install -Syuv
chroot rootfs_mountpoint xbps-install -Sy dracut NetworkManager chrony

# Enable services
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/dbus /etc/runit/runsvdir/default"
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/NetworkManager /etc/runit/runsvdir/default"
chroot rootfs_mountpoint /bin/bash -c "ln -sv /etc/sv/chronyd /etc/runit/runsvdir/default"

mkdir rootfs_mountpoint/repo
mount --bind repo rootfs_mountpoint/repo
chroot rootfs_mountpoint xbps-install -y --repository /repo $PACKAGES
umount rootfs_mountpoint/repo
rm -rf rootfs_mountpoint/repo

cp rootfs_mountpoint/boot/boot.img ../out/

rm rootfs_mountpoint/qemu-aarch64-static
umount -R rootfs_mountpoint
img2simg linux.img ../out/void_base.img
chown 1000:1000 ../out/void_base.img ../out/boot.img
popd