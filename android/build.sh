#!/bin/bash
export USE_CCACHE="1"
export PYTHONDONTWRITEBYTECODE=true
export BUILD_ENFORCE_SELINUX=1
export BUILD_NO=
unset BUILD_NUMBER
#TODO(zif): convert this to a runtime check, grep "sse4_2.*popcnt" /proc/cpuinfo
export CPU_SSE42=false
# Following env is set from build
# VERSION
# DEVICE
# TYPE
# RELEASE_TYPE
# EXP_PICK_CHANGES

if [ -z "BUILD_UUID" ]; then
  export BUILD_UUID=$(uuidgen)
fi

export BUILD_NUMBER=$( (date +%s%N ; echo $BUILD_UUID; hostname) | openssl sha1 | sed -e 's/.*=//g; s/ //g' | cut -c1-10 )

cd /lineage/android
rm -rf .repo/local_manifests/*
if [ -f /lineage/setup.sh ]; then
    source /lineage/setup.sh
fi
yes | repo init -u https://github.com/lineageos/android.git -b ${VERSION}
echo "Resetting build tree"
repo forall -vc "git reset --hard" > /tmp/android-reset.log 2>&1
echo "Syncing"
repo sync -j32 -d --force-sync > /tmp/android-sync.log 2>&1
. build/envsetup.sh
mka clobber
set +e
breakfast lineage_${DEVICE}-${TYPE}
set -e
if [ "$RELEASE_TYPE" '==' "experimental" ]; then
  if [ -z "$EXP_PICK_CHANGES" ]; then
    repopick $EXP_PICK_CHANGES
  fi
fi
mka otatools-package target-files-package dist

ssh jenkins@blob.lineageos.org mkdir -p /home/jenkins/incoming/${DEVICE}/${BUILD_UUID}/
scp out/dist/*target_files*.zip jenkins@blob.lineageos.org:/home/jenkins/incoming/${DEVICE}/${BUILD_UUID}/
scp out/target/product/${DEVICE}/otatools.zip jenkins@blob.lineageos.org:/home/jenkins/incoming/${DEVICE}/${BUILD_UUID}/