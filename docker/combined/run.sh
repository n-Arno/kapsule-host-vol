#!/bin/ash

# check if /k8s-node mount exists
if [ ! -d "/k8s-node" ]; then
  echo "No mount found at /k8s-node"
  exit 1
fi

# generate a test file
uuid=$(cat /proc/sys/kernel/random/uuid)
touch /k8s-node/$uuid

# check if test file is accessible via nsenter
found=$(/usr/bin/nsenter -m/proc/1/ns/mnt -- ls /tmp/scripts | grep $uuid)

if [ "$uuid" != "$found" ]; then
  echo "The host /tmp/scripts folder must be mounted at /k8s-node and accessible via nsenter on PID 1"
  exit 1
fi

# delete test file
rm -f /k8s-node/$uuid

# check for needed API key variables
[ "$SCW_ACCESS_KEY" == "" ] && echo "Missing SCW_ACCESS_KEY" && exit 1
[ "$SCW_SECRET_KEY" == "" ] && echo "Missing SCW_SECRET_KEY" &&  exit 1
[ "$SCW_DEFAULT_ORGANIZATION_ID" == "" ] && echo "Missing SCW_DEFAULT_ORGANIZATION_ID" &&  exit 1
[ "$SCW_DEFAULT_PROJECT_ID" == "" ] && echo "Missing SCW_DEFAULT_PROJECT_ID" && exit 1

# default FOLDER value if absent
FOLDER=${FOLDER:-/data}

# start failing if a command fails
set -eu

# set defaults if not defined
VOL_SIZE=${VOL_SIZE:-1G}
PREFIX=${PREFIX:-addvol}
IOPS=${IOPS:-15000}
WAIT=${WAIT:-yes}

echo "Executing with values: VOL_SIZE=$VOL_SIZE PREFIX=$PREFIX IOPS=$IOPS"

echo "Checking if metadata magic link is reachable, exit otherwise."
curl -sSf -o /dev/null --connect-timeout 1 http://169.254.42.42 

# get all metadata from magic link
echo "Reading instance metadata."
eval $(curl -s http://169.254.42.42/conf | egrep '(^ID=|^ZONE=)')

# search for volume ID by name
echo "Searching for volume ID."
VOL_ID=$(scw block volume list zone=$ZONE name=$PREFIX-$ID -o template='{{ .ID }}')

# Create if not created
if [ "$VOL_ID" == "" ]; then
  echo "Volume is not created, doing so..."
  VOL_ID=$(scw block volume create zone=$ZONE name=$PREFIX-$ID perf-iops=$IOPS from-empty.size=$VOL_SIZE -o template='{{ .ID }}')
else
  echo "Volume already exists."
fi

# Check metadata for volume
VOLUMES=$(curl -s http://169.254.42.42/conf | grep VOLUMES | grep $VOL_ID | wc -l)

# Check if already attached
if [ "$VOLUMES" == "0" ]; then
  echo "Volume is not attached."

  # Attach volume
  echo "Attaching volume..."
  scw instance server attach-volume zone=$ZONE server-id=$ID volume-id=$VOL_ID 1>/dev/null
else
  echo "Volume is already attached."
fi

# copying mount script to host
cp /mount.sh /k8s-node/mount.sh

echo "Starting the mount script in PID 1 namespace"
/usr/bin/nsenter -m/proc/1/ns/mnt -- /tmp/scripts/mount.sh "$VOL_ID" "$FOLDER"

echo "All done!"
