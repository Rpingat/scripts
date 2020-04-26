#!/usr/bin/env bash

device=beryllium
build_type=userdebug
user=jenkins
OUT_PATH="out/target/product/$device"
DATE=$(date '+%d-%b-%Y')

# Export colors
export TERM=xterm
    red=$(tput setaf 1) # red
    grn=$(tput setaf 2) # green
    ylw=$(tput setaf 3) # yellow
    blu=$(tput setaf 4) # blue
    cya=$(tput setaf 6) # cyan
    txtrst=$(tput sgr0) # Reset

#Reset trees & Sync with latest source
if [ "$reset" = "yes" ];
then
rm -rf .repo/local_manifests
echo -e ${ylw}"Resetting current working tree...."${txtrst}
repo forall -c "git reset --hard" > /dev/null
echo -e ${ylw}"Reset complete!"${txtrst}
repo forall -c "git clean -f -d"
echo -e ${ylw}"Syncing latest sources"${txtrst}
repo sync --force-sync --no-tags --no-clone-bundle
fi

# Export ccache
if [ "$use_ccache" = "yes" ];
then
echo -e ${blu}"CCACHE is enabled for this build"${txtrst}
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
export CCACHE_COMPRESS=1
export CCACHE_DIR=/var/lib/jenkins/ccache/$user
ccache -M 200G
fi

#Clear ccache
if [ "$use_ccache" = "clean" ];
then
export CCACHE_EXEC=$(which ccache)
export CCACHE_DIR=/var/lib/jenkins/ccache/$user
ccache -C
export USE_CCACHE=1
export CCACHE_COMPRESS=1
ccache -M 200G
wait
echo -e ${grn}"CCACHE Cleared"${txtrst};
fi

#Export  variables
export KBUILD_BUILD_USER=AiM
export KBUILD_BUILD_HOST=Jenkins
export AIM_BUILD_TYPE=Official

#Gapps
if [ "gapps" = "yes" ];
then
WITH_GAPPS=true
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
rm -rf $OUT_PATH/AIM*.zip
wait
echo -e ${cya}"Images deleted from OUT dir"${txtrst};
fi

#Time to build
source build/envsetup.sh
lunch aim_${device}-"$build_type"
telegram-send --format html "Build started for <b>${device}</b> on jenkins <a href='${BUILD_URL}console'>here</a>!"
make bacon -j8

export SSHPASS=""

# If the build is successful
if [ `ls $OUT_PATH/AIM-System-V4.*.zip 2>/dev/null | wc -l` != "0" ]; then
   telegram-send "Build successful for ${device}, uploading."

   cd $OUT_PATH
   AIM="$(ls AIM-System-V4.*.zip)"

   echo "Uploading to Sourceforge"
   ~/sshpass -e sftp -oBatchMode=no -b - ravi9967@frs.sourceforge.net << !
     cd /home/frs/project/aim-rom-ten/$device
     put ${AIM}
     bye
!

DOWNLOAD_LINK=https://sourceforge.net/projects/aim-rom-ten/files/${device}/${AIM}/download

   #variables for json
   datetime=$(grep ro\.build\.date\.utc system/build.prop | cut -d= -f2)
   filename=${AIM}
   size=$(stat -c%s $AIM)
   id=$(sha256sum $AIM | awk '{ print $1 }')
   url=${DOWNLOAD_LINK}
   version=V4.1

cd ../../../../

#generate ota json
jq -n --arg id $id --arg filename $filename --arg url $url --arg datetime $datetime --arg size $size --arg version $version '{"response":[{ "datetime": $datetime, "filename": $filename, "id": $id, "size": $size, "url": $url, "version": $version,}]}' > ${device}.json

telegram-send "Build uploaded"

else
telegram-send --format html "Build for ${device} failed. Check what caused your build to fail <a href='${BUILD_URL}console'>here</a>!"
exit 1
fi
