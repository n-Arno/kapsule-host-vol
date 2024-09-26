#!/bin/sh

# Validate input
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <VOLUME_ID> <FOLDER>"
  exit 1
fi

VOLUME_ID=$1
FOLDER=$2

set -eu

# Starting
echo "Executing with values: VOLUME_ID=$VOLUME_ID FOLDER=$FOLDER"

# Test access to metadata"
echo "Checking if metadata magic link is reachable, exit otherwise."
curl -sSf -o /dev/null --connect-timeout 1 http://169.254.42.42

# Wait 1s
echo "Sleep for a second to ensure metadata are up to date"
sleep 1

# check metadata for volume by id
echo "Checking instance metadata for VOLUME_ID, exit if not found"
curl -s http://169.254.42.42/conf | grep VOLUMES | grep $VOLUME_ID > /dev/null

# find associated device
echo "Finding associated device."
DEVICE=$(readlink -f /dev/disk/by-id/scsi-0SCW_sbs_volume-$VOLUME_ID)

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

echo "Mount done!"
