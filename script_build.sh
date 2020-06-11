#!/usr/bin/env bash

# Export ccache
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
export CCACHE_COMPRESS=1
export CCACHE_DIR=/path/to/ccache
ccache -M 75G

#Clear ccache
#export CCACHE_EXEC=$(which ccache)
#export CCACHE_DIR=/path/to/ccache
#ccache -C
#export USE_CCACHE=1
#export CCACHE_COMPRESS=1
#ccache -M 75G

#Export User and host variables
export KBUILD_BUILD_USER=AiM
export KBUILD_BUILD_HOST=Jenkins

# clean
make clean && make clobber

#Time to build
source build/envsetup.sh
lunch aim_beryllium-userdebug
make bacon -j8
