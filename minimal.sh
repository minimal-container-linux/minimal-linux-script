#!/bin/sh
set -ex
KERNEL_VERSION=$(wget -O - https://linux-libre.fsfla.org/pub/linux-libre/releases/ | sed "s/.*href=\"//g;s/-gnu.*//g" | grep -e "^[0-9]" | sort -V | tail -n 1)
BUSYBOX_VERSION=$(wget -O - https://busybox.net/downloads/ | sed "s/.*href=\"//g;s/\".*//g" | grep "^busybox-[0-9]" | grep "bz2$" | sort -V | tail -n 1 | sed "s/busybox-//g;s/.tar.bz2//g")
SYSLINUX_VERSION=6.03
wget -O kernel.tar.xz http://linux-libre.fsfla.org/pub/linux-libre/releases/${KERNEL_VERSION}-gnu/linux-libre-${KERNEL_VERSION}-gnu.tar.xz
wget -O busybox.tar.bz2 http://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
wget -O syslinux.tar.xz http://kernel.org/pub/linux/utils/boot/syslinux/syslinux-${SYSLINUX_VERSION}.tar.xz
tar -xvf kernel.tar.xz
tar -xvf busybox.tar.bz2
tar -xvf syslinux.tar.xz
mkdir isoimage
cd busybox-${BUSYBOX_VERSION}
make distclean defconfig
sed -i "s|.*CONFIG_STATIC.*|CONFIG_STATIC=y|" .config
make busybox install
cd _install
rm -f linuxrc
mkdir dev proc sys
echo '#!/bin/sh' > init
echo 'dmesg -n 1' >> init
echo 'mount -t devtmpfs none /dev' >> init
echo 'mount -t proc none /proc' >> init
echo 'mount -t sysfs none /sys' >> init
echo 'setsid cttyhack /bin/sh' >> init
chmod +x init
find . | cpio -R root:root -H newc -o | gzip > ../../isoimage/rootfs.gz
cd ../../linux-${KERNEL_VERSION}
make mrproper defconfig bzImage
cp arch/x86/boot/bzImage ../isoimage/kernel.gz
cd ../isoimage
cp ../syslinux-${SYSLINUX_VERSION}/bios/core/isolinux.bin .
cp ../syslinux-${SYSLINUX_VERSION}/bios/com32/elflink/ldlinux/ldlinux.c32 .
echo 'default kernel.gz initrd=rootfs.gz' > ./isolinux.cfg
xorriso \
  -as mkisofs \
  -o ../minimal_linux_live.iso \
  -b isolinux.bin \
  -c boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  ./
cd ..
set +ex
