#!/bin/sh

FOLDER=$1
FOLDER=${FOLDER:-/data}

set -eu

# get volume id from medata
echo "Reading instance metadata."
eval $(curl -s http://169.254.42.42/conf | egrep '(^VOLUMES_1_ID=)')

# find associated device
echo "Find associated device."
DEVICE=$(readlink -f /dev/disk/by-id/scsi-0SCW_sbs_volume-$VOLUMES_1_ID)

echo "Checking if $DEVICE is formatted..."
FORMAT=$(lsblk $DEVICE -no fstype)
if [ "$FORMAT" != "ext4" ]; then
  echo "Formatting $DEVICE to ext4."
  mkfs.ext4 -q $DEVICE
fi

echo "Checking if $DEVICE is mounted..."
MOUNTED=$(mount | grep $DEVICE | wc -l)
if [ $MOUNTED -eq 0 ]; then
  echo "Mounting $DEVICE to $FOLDER."
  mkdir -p $FOLDER
  mount $DEVICE $FOLDER
fi

echo "Done!"
