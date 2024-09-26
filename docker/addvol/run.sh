#!/bin/ash

# check for needed API key variables
[ "$SCW_ACCESS_KEY" == "" ] && echo "Missing SCW_ACCESS_KEY" && exit 1
[ "$SCW_SECRET_KEY" == "" ] && echo "Missing SCW_SECRET_KEY" &&  exit 1
[ "$SCW_DEFAULT_ORGANIZATION_ID" == "" ] && echo "Missing SCW_DEFAULT_ORGANIZATION_ID" &&  exit 1
[ "$SCW_DEFAULT_PROJECT_ID" == "" ] && echo "Missing SCW_DEFAULT_PROJECT_ID" && exit 1

set -eu

# set defaults if not defined
VOL_SIZE=${VOL_SIZE:-1G}
PREFIX=${PREFIX:-addvol}
IOPS=${IOPS:-15000}
WAIT=${WAIT:-yes}

echo "Executing with values: VOL_SIZE=$VOL_SIZE PREFIX=$PREFIX IOPS=$IOPS"

echo "Checking if metadata magic link is reachable, exit otherwise."
ping -c 1 -W 1 169.254.42.42 1>/dev/null 

# get all metadata from magic link
echo "Reading instance metadata."
eval $(curl -s http://169.254.42.42/conf | egrep '(^NAME=|^ID=|^ZONE=|^VOLUMES=)')

# search for volume ID associated to the name
echo "Searching for volume ID."
VOL_ID=$(scw block volume list zone=$ZONE name=$PREFIX-$ID -o template='{{ .ID }}')

# Check if already attached
if [ "$VOLUMES" == "0" ]; then
  echo "No volume found attached."

  # Create if not created
  if [ "$VOL_ID" == "" ]; then
    echo "Volume is not created, doing so..."
    VOL_ID=$(scw block volume create zone=$ZONE name=$PREFIX-$ID perf-iops=$IOPS from-empty.size=$VOL_SIZE -o template='{{ .ID }}')
  fi

  # Attach volume
  echo "Attaching volume..."
  scw instance server attach-volume zone=$ZONE server-id=$ID volume-id=$VOL_ID 1>/dev/null
else
  echo "Volume is already attached."
fi

echo "Done!"
