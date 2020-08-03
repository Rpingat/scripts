#!/usr/bin/env bash

# Export some variables
user=
OUT_PATH="out/target/product/$device"
ROM_ZIP="AIM*.zip"

# Export colors
export TERM=xterm
    red=$(tput setaf 1) # red
    grn=$(tput setaf 2) # green
    ylw=$(tput setaf 3) # yellow
    blu=$(tput setaf 4) # blue
    cya=$(tput setaf 6) # cyan
    txtrst=$(tput sgr0) # Reset

# Export ccache
if [ "$use_ccache" = "yes" ];
then
echo -e ${blu}"CCACHE is enabled for this build"${txtrst}
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
export CCACHE_COMPRESS=1
export CCACHE_DIR=/home/${user}/ccache
ccache -M 75G
fi

#Clear ccache
if [ "$use_ccache" = "clean" ];
then
export CCACHE_EXEC=$(which ccache)
export CCACHE_DIR=/home/${user}/ccache
ccache -C
export USE_CCACHE=1
export CCACHE_COMPRESS=1
ccache -M 75G
wait
echo -e ${grn}"CCACHE Cleared"${txtrst};
fi

# clean
if [ "$make_clean" = "yes" ];
then
make clean && make clobber
wait
echo -e ${cya}"OUT dir from your repo deleted"${txtrst};
fi

if [ "$make_clean" = "installclean" ];
then
make installclean
rm -rf $OUT_PATH/$ROM_ZIP
wait
echo -e ${cya}"Images deleted from OUT dir"${txtrst};
fi

#Time to build
source build/envsetup.sh
lunch aim_${device}-"$build_type"
make bacon -j32