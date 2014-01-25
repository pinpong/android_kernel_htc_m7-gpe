#!/bin/bash

# private environment
TOOLCHAIN=/home/pinpong/android/toolchain/gcc-linaro-armeb-linux-gnueabihf-4.8-2013.10_linux/bin/armeb-linux-gnueabihf-
KERNEL_DIR=/home/pinpong/android/android_kernel_htc_m7-gpe
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

# remove backup, modules and log files
echo $(date) 'remove backup, modules and log files'
if [ -d $CWM/m7-cwm_zip/system/lib/modules ] ; then
	find $CWM -name '*.ko' | xargs rm
else
	mkdir -p $CWM/m7-cwm_zip/system/lib/modules
fi

find $KERNEL_DIR -name '*~' | xargs rm

# make kernel
echo $(date) 'make kernel'
make 'thoravukk_m7_defconfig'
make -j`grep 'processor' /proc/cpuinfo | wc -l` CROSS_COMPILE=$TOOLCHAIN

# copy modules
echo $(date) 'copy modules'
find -name '*.ko' -exec cp -av {} $CWM/m7-cwm_zip/system/lib/modules/ \;

# copy kernel image
echo $(date) 'copy kernel image'
cp arch/arm/boot/zImage $CWM/m7-cwm_zip/kernel/kernel

# strip modules
echo $(date) 'strip modules'
${TOOLCHAIN}strip --strip-unneeded $CWM/m7-cwm_zip/system/lib/modules/*ko

# create cwm zip
echo $(date) 'create cwm zip'
TIMESTAMP=thoravukk-`date +%Y%m%d-%T`
cd $CWM/m7-cwm_zip
zip -r m7-$TIMESTAMP-cwm.zip . -x *.zip
rm $CWM/m7-cwm_zip/kernel/kernel
