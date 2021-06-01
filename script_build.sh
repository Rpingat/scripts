#!/usr/bin/env bash

user=

# Export ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
export CCACHE_COMPRESS=1
export CCACHE_DIR=/home/$user/ccache
ccache -M 75G

#Clear ccache
#export CCACHE_EXEC=$(which ccache)
#export CCACHE_DIR=/path/to/ccache
#ccache -C
#export USE_CCACHE=1
#export CCACHE_COMPRESS=1
#ccache -M 75G

#Export User and host variables
export KBUILD_BUILD_USER=$user
export KBUILD_BUILD_HOST=ThunderServer

#Time to 
source build/envsetup.sh
make clean
lunch lineage_device-userdebug
make bacon -j16
