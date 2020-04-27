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
    ylw=$(tput setaf 3) #  yellow
    blu=$(tput setaf 4) # blue
    cya=$(tput setaf 6) # cyan
    txtrst=$(tput sgr0) # Reset

#Reset trees & Sync with latest source
rm -rf .repo/local_manifests
echo -e ${ylw}"Resetting current working tree...."${txtrst}
repo forall -c "git reset --hard" > /dev/null
echo -e ${ylw}"Reset complete!"${txtrst}
repo forall -c "git clean -f -d"
echo -e ${ylw}"Syncing latest sources"${txtrst}
repo sync --force-sync --no-tags --no-clone-bundle

# Export ccache
echo -e ${blu}"CCACHE is enabled for this build"${txtrst}
export CCACHE_EXEC=$(which ccache)
export USE_CCACHE=1
export CCACHE_COMPRESS=1
export CCACHE_DIR=/var/lib/jenkins/ccache/$user
ccache -M 200G

#Clear ccache
#export CCACHE_EXEC=$(which ccache)
#export CCACHE_DIR=/var/lib/jenkins/ccache/$user
#ccache -C
#export USE_CCACHE=1
#export CCACHE_COMPRESS=1
#ccache -M 200G
#wait
#echo -e ${grn}"CCACHE Cleared"${txtrst};

#Export User and host variables
export KBUILD_BUILD_USER=AiM
export KBUILD_BUILD_HOST=Jenkins

# clean
make clean && make clobber
wait
echo -e ${cya}"OUT dir from your repo deleted"${txtrst}

#make installclean
#wait
#echo -e ${cya}"Images deleted from OUT dir"${txtrst};

#Time to build
source build/envsetup.sh
lunch aim_${device}-"$build_type"
make bacon -j8

export SSHPASS=""

if [ `ls $OUT_PATH/AIM-System-V4.*.zip 2>/dev/null | wc -l` != "0" ];
then
   BUILD_RESULT=Success
else
   telegram-send --format html "Build for ${device} failed."
fi

if [ "$BUILD_RESULT" = "Success" ];
then
if [ `ls $OUT_PATH/AIM-System-V4.*Lucid*.zip 2>/dev/null | wc -l` != "0" ];
then

   cd $OUT_PATH
   LUCID="$(ls AIM-System-V4.*Lucid*.zip)"

   echo "Uploading to Google Drive"
   gdrive upload ${LUCID} -p ${folderid}

   echo "Uploading to Sourceforge"
   ~/sshpass -e sftp -oBatchMode=no -b - ravi9967@frs.sourceforge.net << !
     cd /home/frs/project/aim-rom-ten/$device
     put ${LUCID}
     bye
!

   LUCID_SF=https://sourceforge.net/projects/stagos-10/files/${device}/${LUCID}
   lucid_size=$(du -sh $LUCID | awk '{print $1}')
   lucid_md5=$(md5sum $LUCID | awk '{print $1}' )

   #variables for lucid json
   datetime=$(grep ro\.build\.date\.utc system/build.prop | cut -d= -f2)
   filename=${LUCID}
   size=$(stat -c%s $LUCID)
   id=$(sha256sum $LUCID | awk '{ print $1 }')
   url=${LUCID_SF}
   version=V4.1

#generate lucid ota json
jq -n --arg id $id --arg filename $filename --arg url $url --arg datetime $datetime --arg size $size --arg version $version '{"response":[{ "datetime": $datetime, "filename": $filename, "id": $id, "size": $size, "url": $url, "version": $version,}]}' > lucid.json
cd ../../../../
fi
fi

if [ "$BUILD_RESULT" = "Success" ];
then
export WITH_GAPPS=true
source build/envsetup.sh
lunch aim_${device}-"$build_type"
make bacon -j8
fi

if [ "$BUILD_RESULT" = "Success" ];
then
if [ `ls $OUT_PATH/AIM-System-V4.*GApps*.zip 2>/dev/null | wc -l` != "0" ];
then

   cd $OUT_PATH
   GAPPS="$(ls AIM-System-V4.*GApps*.zip)"

   echo "Uploading to Sourceforge"
   ~/sshpass -e sftp -oBatchMode=no -b - ravi9967@frs.sourceforge.net << !
     cd /home/frs/project/aim-rom-ten/$device
     put ${GAPPS}
     bye
!

   GAPPS_SF=https://sourceforge.net/projects/stagos-10/files/${device}/${GAPPS}
   gapps_size=$(du -sh $GAPPS | awk '{print $1}')
   gapps_md5=$(md5sum $GAPPS | awk '{print $1}' )

   #variables for gapps json
   datetime=$(grep ro\.build\.date\.utc system/build.prop | cut -d= -f2)
   filename=${GAPPS}
   size=$(stat -c%s $GAPPS)
   id=$(sha256sum $GAPPS | awk '{ print $1 }')
   url=${GAPPS_SF}
   version=V4.1

#generate gapps ota json
jq -n --arg id $id --arg filename $filename --arg url $url --arg datetime $datetime --arg size $size --arg version $version '{"response":[{ "datetime": $datetime, "filename": $filename, "id": $id, "size": $size, "url": $url, "version": $version,}]}' > gapps.json
fi
fi

if [ "$BUILD_RESULT" = "Success" ];
then
hashtag="#${device} #letsaimify"
read -r -d '' msg <<EOT
<b>New build available for ${devicename}($device) </b>

<b>Maintainer:</b> ${maintainer}
<b>Build Date:</b> $DATE

<b>Lucid Variant</b>
<b>Download:</b> <a href="${LUCID_SF}">Click Here</a>
<b>FileSize:</b> $lucid_size
<b>MD5:</b> <code>$lucid_md5</code>

<b>GApps Variant</b>
<b>Download:</b> <a href="${GAPPS_SF}">Click Here</a>
<b>FileSize:</b> $gapps_size
<b>MD5:</b> <code>$gapps_md5</code>

${hashtag}

Discussions: @aimofficial
Official Channel: @aimromofficial
EOT

   telegram-send --format html --disable-web-page-preview "${msg}"
   telegram-send --file lucid.json
   telegram-send --file gapps.json

cd ../../../../
fi
