#!/bin/bash

# private environment
KERNEL_DIR=/home/pinpong/android/android_kernel_htc_m7-gpe
CWM=$KERNEL_DIR/cwm_zip
TOOLCHAIN=/home/pinpong/android/toolchain/gcc-linaro-armeb-linux-gnueabihf-4.8-2013.10_linux/bin/armeb-linux-gnueabihf-
export ARCH=arm
export SUBARCH=arm

rm 'compile.log'
exec >> $KERNEL_DIR/compile.log
exec 2>&1

# cd kernel source
echo $(date) 'cd kernel source'
cd $KERNEL_DIR

# make mrproper
echo $(date) 'make mrproper'
make CROSS_COMPILE=$TOOLCHAIN -j`grep 'processor' /proc/cpuinfo | wc -l` mrproper

# remove backup, placeholder, modules and log files
echo $(date) 'remove backup, placeholder, modules and log files'
find $CWM -name 'placeholder' | xargs rm
find $CWM -name '*.ko' | xargs rm
find $KERNEL_DIR -name '*~' | xargs rm

# make kernel
echo $(date) 'make kernel'
make 'thoravukk_m7_defconfig'
make -j`grep 'processor' /proc/cpuinfo | wc -l` CROSS_COMPILE=$TOOLCHAIN

# copy modules
echo $(date) 'copy modules'
find -name '*.ko' -exec cp -av {} $CWM/m7-gpe-cwm_zip/system/lib/modules/ \;

# strip modules
echo $(date) 'strip modules'
${TOOLCHAIN}strip --strip-unneeded $CWM/m7-gpe-cwm_zip/system/lib/modules/*ko

# create ramdisk and make boot.img
echo $(date) 'create ramdisk and make boot.img'
cd $CWM/ramdisk
find . | cpio -o -H newc | gzip > ../ramdisk.gz
mkbootimg --kernel $KERNEL_DIR/arch/arm/boot/zImage --ramdisk $CWM/ramdisk.gz --output $CWM/m7-gpe-cwm_zip/boot.img

echo $(date) 'create cwm zip'
TIMESTAMP=thoravukk-`date +%Y%m%d-%T`
cd $CWM/m7-gpe-cwm_zip
zip -r m7-$TIMESTAMP-cwm.zip . -x *.zip
rm $CWM/m7-gpe-cwm_zip/boot.img
rm $CWM/ramdisk.gz
