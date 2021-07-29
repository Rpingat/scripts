#!/usr/bin/env bash

# curl https://raw.githubusercontent.com/Rpingat/scripts/master/script_build.sh>script_build.sh
# Make necessary changes before executing script

# Export some variables
user=
device_codename=
lunch=
build_type=
OUT_PATH="out/target/product/$device_codename"
ROM_ZIP=*.zip
tg_username=@

read -r -d '' msg <<EOT
<b>Build Started</b>

<b>Device:-</b> ${device_codename}
<b>Job Number:-</b> ${BUILD_NUMBER}
<b>Started by:-</b> ${tg_username}

Check progress <a href="${BUILD_URL}console">HERE</a>
EOT
telegram-send --format html "$msg"

# Ccache
if [ "$use_ccache" = "yes" ];
then
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
fi

rm -rf ${OUT_PATH}/${ROM_ZIP} #clean rom zip in any case

# Time to build
source build/envsetup.sh
# Make clean
if [ "$make_clean" = "yes" ];
then
make clean
wait
fi

if [ "$make_clean" = "installclean" ];
then
make installclean
wait
fi
lunch "$lunch"_"$device_codename"-"$build_type"
START=$(date +%s)
make bacon -j24
END=$(date +%s)
TIME=$(echo $((${END}-${START})) | awk '{print int($1/60)" Minutes and "int($1%60)" Seconds"}')

if [ `ls $OUT_PATH/$ROM_ZIP 2>/dev/null | wc -l` != "0" ]; then
cd $OUT_PATH
RZIP="$(ls ${ROM_ZIP})"
cp ${RZIP} /home/ravi/builds/${user}
link="https://mirror1.thunderserver.in/$user/$RZIP"
read -r -d '' suc <<EOT
<b>Build Finished</b>

<b>Time:-</b> ${TIME}
<b>Device:-</b> ${device_codename}
<b>Build status:-</b> Success
<b>Download:-</b> <a href="${link}">$RZIP</a>

Check console output <a href="${BUILD_URL}console">HERE</a>

cc: ${tg_username}
EOT
telegram-send --format html "$suc"
else

read -r -d '' fail <<EOT
<b>Build Finished</b>

<b>Time:-</b> ${TIME}
<b>Device:-</b> ${device_codename}
<b>Build status:-</b> Failed

Check what caused build to fail <a href="${BUILD_URL}console">HERE</a>

cc: ${tg_username}
EOT
telegram-send --format html "$fail"

exit 1
fi
