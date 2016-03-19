#!/bin/bash

# Bash Color
green='\033[01;32m'
red='\033[01;31m'
blink_red='\033[05;31m'
restore='\033[0m'

clear

# Resources
THREAD="-j$(grep -c ^processor /proc/cpuinfo)"
KERNEL="Image"
DTBIMAGE="dtb"
DEFCONFIG="leo_nian_defconfig"
KERNEL_DIR=`pwd`
RESOURCE_DIR="$KERNEL_DIR/.."
ANYKERNEL_DIR="$RESOURCE_DIR/Nian-leo-AnyKernel2"

# Device Info
TARGET_DEVICE="leo"
BUILD_MOD=Nian

# kernel vesion
ANDROID_VERSION=M
if [ ! "$RELEASE_BUILD" = 'y' ]; then
  BUILD_VERSION=`date +%Y%m%d`
  
  if [ -n "$BUILD_NUMBER" ]; then
    BUILD_VERSION=`date +%Y%m%d`"#$BUILD_NUMBER"
    export KBUILD_BUILD_VERSION="$BUILD_NUMBER"
  fi
fi

KERNEL_VERSION=`grep '^VERSION = ' ./Makefile | cut -d' ' -f3`
KERNEL_PATCHLEVEL=`grep '^PATCHLEVEL = ' ./Makefile | cut -d' ' -f3`
KERNEL_SUBLEVEL=`grep '^SUBLEVEL = ' ./Makefile | cut -d' ' -f3`
export BUILD_KERNELVERSION="$KERNEL_VERSION.$KERNEL_PATCHLEVEL.$KERNEL_SUBLEVEL"
export Nian_VER="$TARGET_DEVICE-$ANDROID_VERSION-$BUILD_MOD-$BUILD_VERSION"

# Vars
export LOCALVERSION=~`echo $Nian_VER`
export CROSS_COMPILE="../gcc/bin/aarch64-linux-android-"
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER=nian
export KBUILD_BUILD_HOST=Nian-MacBookPro

# Paths
REPACK_DIR="$ANYKERNEL_DIR"
PATCH_DIR="$ANYKERNEL_DIR/patch"
MODULES_DIR="$ANYKERNEL_DIR/modules"
ZIP_MOVE="$RESOURCE_DIR/Nian-releases.zip"
ZIMAGE_DIR="$KERNEL_DIR/arch/arm64/boot"

# Functions
function clean_all {
		echo; ccache -c -C echo;
		if [ -f "$MODULES_DIR/*.ko" ]; then
			rm `echo $MODULES_DIR"/*.ko"`
		fi
		cd $REPACK_DIR
		rm -rf $KERNEL
		rm -rf $DTBIMAGE
		git reset --hard > /dev/null 2>&1
		git clean -f -d > /dev/null 2>&1
		cd $KERNEL_DIR
		echo
		make clean && make mrproper
}

function make_kernel {
		echo
		make $DEFCONFIG
		make $THREAD
		cp -vr $ZIMAGE_DIR/$KERNEL $REPACK_DIR/zImage
}

function make_modules {
		if [ -f "$MODULES_DIR/*.ko" ]; then
			rm `echo $MODULES_DIR"/*.ko"`
		fi
		#find $MODULES_DIR/proprietary -name '*.ko' -exec cp -v {} $MODULES_DIR \;
		find $KERNEL_DIR -name '*.ko' -exec cp -v {} $MODULES_DIR \;
}

function make_dtb {
		$REPACK_DIR/tools/dtbtool -o $REPACK_DIR/$DTBIMAGE -s 2048 -p scripts/dtc/ arch/arm64/boot/dts/
}

function make_zip {
		cd $REPACK_DIR
		zip -x@zipexclude -r9 `echo $Nian_Version`.zip *
		mv  `echo $Nian_Version`.zip $ZIP_MOVE
		cd $KERNEL_DIR
}


DATE_START=$(date +"%s")

echo -e "${green}"
echo "====================================================================="
echo "    BUILD START (KERNEL VERSION $BUILD_KERNELVERSION-$Nian_VER)"
echo "====================================================================="
echo -e "${restore}"

while read -p "Do you want to clean stuffs (y/n)? " cchoice
do
case "$cchoice" in
	y|Y )
		clean_all
		echo
		echo "All Cleaned now."
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo

while read -p "Do you want to build kernel (y/n)? " dchoice
do
case "$dchoice" in
	y|Y)
		make_kernel
		make_dtb
		make_modules
		make_zip
		break
		;;
	n|N )
		break
		;;
	* )
		echo
		echo "Invalid try again!"
		echo
		;;
esac
done

echo -e "${green}"
echo "====================================================================="
echo "                       Build Completed in:"
echo "====================================================================="
echo -e "${restore}"

DATE_END=$(date +"%s")
DIFF=$(($DATE_END - $DATE_START))
echo "Time: $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
echo


