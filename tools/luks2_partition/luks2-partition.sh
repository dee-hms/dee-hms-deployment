#!/bin/bash
#
# Copyright 2023 Sergio Arroutbi <sarroutb@redhat.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
function usage() {
  echo
  echo "$0 -d device [-h] [-v]"
  echo
  echo "Example:"
  echo "        $0 -d /dev/xvdb"
  echo "        $0 -d /dev/xvdb -v"
  echo "        $0 -h"
  echo
  exit "$2"
}

YES=""
DEVICE=""
INPUT_OPT=""
LUKS_PASSWORD=""
MOUNT_DIRECTORY="/mnt/encrypted"

# Check executed as root

while getopts "d:p:m:hv" arg
do
  case "${arg}" in
    d) DEVICE=${OPTARG}
       ;;
    p) LUKS_PASSWORD=${OPTARG}
       ;;
    m) MOUNT_DIRECTORY=${OPTARG}
       ;;
    h) usage $0 0
       ;;
    v) set -x
       ;;
  esac
done

if [ -z "${DEVICE}" ];
then
    usage $0 1
fi

if [ -z "${YES}" ];
then
    echo "WARNING: ALL DATA IN ${DEVICE} WILL BE LOST."
    read -p "Are you sure you want to format device:[${DEVICE}] with LUKS2 format? (y/N):" INPUT_OPT
fi

if [ "${INPUT_OPT}" != "y" ];
then
    echo "Exiting ..."
    exit 0
fi

# Partition as luks
if [ -n "${LUKS_PASSWORD}" ];
then
    echo -n "${LUKS_PASSWORD}" | cryptsetup luksFormat --batch-mode --key-file - ${DEVICE}
else
    cryptsetup luksFormat --batch-mode ${DEVICE}
fi

# Open
echo "Opening device ${device} to format in EXT4 mode ..."
if [ -n "${LUKS_PASSWORD}" ];
then
    echo -n "${LUKS_PASSWORD}" | cryptsetup luksOpen "${DEVICE}" encrypted
else
    cryptsetup luksOpen "${DEVICE}" encrypted
fi

# Partition
mkfs.ext4 /dev/mapper/encrypted

# Get UID (OF THE DEVICE !!!)
TRIMMED_DEVICE=$(echo ${DEVICE} | sed s-/dev/--g)
UUID=$(lsblk --fs | grep ${TRIMMED_DEVICE} | awk '{print $4}')

if [ -z "${UUID}" ];
then
    echo "WARNING: Unable to guess UUID"
    exit 0
fi

# Set crypttab as expected, with none, nofail
grep "luks-${UUID} UUID=${UUID} none nofail" /etc/crypttab 2>&1 > /dev/null || {
    echo "luks-${UUID} UUID=${UUID} none nofail" >> /etc/crypttab
}

# Set fstab as expected, with next options:
grep "/dev/mapper/luks-${UUID} ${MOUNT_DIRECTORY} ext4  auto,nofail,noatime,rw,user 0 0"\
     /etc/fstab 2>&1 > /dev/null || {
    echo "/dev/mapper/luks-${UUID} ${MOUNT_DIRECTORY} ext4  auto,nofail,noatime,rw,user 0 0" \
         >> /etc/fstab
}
