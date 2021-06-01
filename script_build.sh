#!/usr/bin/env bash

# curl https://raw.githubusercontent.com/Rpingat/scripts/master/script_build.sh>script_build.sh
# Make necessary changes before executing script

# Export some variables
user=
device_codename=
OUT_PATH="out/target/product/$device_codename"
ROM_ZIP=Rom*.zip

# Colors makes things beautiful
export TERM=xterm

    red=$(tput setaf 1)             #  red
    grn=$(tput setaf 2)             #  green
    blu=$(tput setaf 4)             #  blue
    cya=$(tput setaf 6)             #  cyan
    txtrst=$(tput sgr0)             #  Reset

# Ccache
if [ "$use_ccache" = "yes" ];
then
echo -e ${blu}"CCACHE is enabled for this build"${txtrst}
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
export CCACHE_DIR=/home/$user/ccache
ccache -M 50G
fi

if [ "$use_ccache" = "clean" ];
then
export CCACHE_EXEC=$(which ccache)
export CCACHE_DIR=/home/$user/ccache
ccache -C
export USE_CCACHE=1
ccache -M 50G
wait
echo -e ${grn}"CCACHE Cleared"${txtrst};
fi

rm -rf ${OUT_PATH}/${ROM_ZIP} #clean rom zip in any case

# Time to build
source build/envsetup.sh
# Make clean
if [ "$make_clean" = "yes" ];
then
make clean
wait
echo -e ${cya}"OUT dir from your repo deleted"${txtrst};
fi

if [ "$make_clean" = "installclean" ];
then
make installclean
wait
echo -e ${cya}"Images deleted from OUT dir"${txtrst};
fi
lunch lineage_"$device_codename"-userdebug
make bacon -j16

if [ `ls $OUT_PATH/$ROM_ZIP 2>/dev/null | wc -l` != "0" ]; then
cd $OUT_PATH
RZIP="$(ls ${ROM_ZIP})"
cp ${RZIP} /home/ravi/$user
fi
