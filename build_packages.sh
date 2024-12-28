#!/usr/bin/env bash
source ./env.sh

if [ ! -d $WORKDIR ]; then
	mkdir $WORKDIR
fi

pushd $WORKDIR

if [ ! -d "xbps-static" ];then
	wget $XBPS_URI -O xbps-static.tar.xz
	mkdir xbps-static
	tar xvf xbps-static.tar.xz -C xbps-static
fi

export PATH=$(realpath xbps-static/usr/bin):$PATH

if [ ! -d "void-packages" ]; then
	git clone https://github.com/void-linux/void-packages --depth=1

fi
cp -r ../packages/* void-packages/srcpkgs/


if [ ! -d "repo" ]; then
	mkdir repo
	cd void-packages
	XBPS_ALLOW_CHROOT_BREAKOUT=1 ./xbps-src binary-bootstrap
	XBPS_ALLOW_CHROOT_BREAKOUT=1 ./xbps-src -a aarch64 pkg $PACKAGES
	cp -rv hostdir/binpkgs/* ../repo
	cd ..
fi

popd
