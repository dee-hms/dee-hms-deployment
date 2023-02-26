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
  echo "$0 -d device [-m mount_directory] [-p password] [-h] [-v] [-y]"
  echo
  echo "Examples:"
  echo "        $0 -d /dev/xvdb"
  echo "        $0 -d /dev/xvdb -p passWordToUse_ -m /mnt/encdata -y"
  echo
  echo "Options:"
  echo "        -d \"device\": device to format (mandatory)"
  echo "        -m \"mount_point\": (/mnt/encrypted by default)"
  echo "        -p \"password\": (LUKS2 master password, if not provided, it will be asked)"
  echo "        -h: help"
  echo "        -v: verbose"
  echo "        -y: automatically answer yes for all questions (requires -p)"
  echo
  exit "$2"
}

YES=""
DEVICE=""
INPUT_OPT=""
LUKS_PASSWORD=""
MOUNT_DIRECTORY="/mnt/encrypted"
DEPENDENCIES=(cryptsetup)

# Check executed as root

install_dependency() {
    echo "Installing dependency[${2}]: ${1}"
    dnf install -y "${1}"
}

while getopts "d:p:m:hvy" arg
do
  case "${arg}" in
    d) DEVICE=${OPTARG}
       ;;
    p) LUKS_PASSWORD=${OPTARG}
       ;;
    m) MOUNT_DIRECTORY=${OPTARG}
       ;;
    h) usage "$0" 0
       ;;
    y) YES="1"
       INPUT_OPT="y"
       ;;
    v) set -x
       ;;
    *) usage "$0" 1
       ;;
  esac
done

if [ -z "${DEVICE}" ];
then
    usage "$0" 1
fi

ID=$(id -u)
if [ "${ID}" != "0" ];
then
    echo
    echo "This has to be executed as root user"
    echo
    exit 1
fi

if [ "${YES}" == "1" ] && [ -z "${LUKS_PASSWORD}" ];
then
    echo
    echo "Need to provide LUKS2 password to use -y mode!!!"
    usage "$0" 1
fi

if [ -z "${YES}" ];
then
    printf -v deps ' %s' "${DEPENDENCIES[@]}"
    printf 'Install required dependencies:(%s)? ' "${deps:1}"
    read -r -p "[y/N]:" INPUT_OPT
    if [ "${INPUT_OPT}" != "y" ];
    then
        echo "Exiting ..."
        exit 0
    fi
fi

for ((dep=0; dep<${#DEPENDENCIES[*]}; dep++))
do
    rpm -qi "${DEPENDENCIES[$dep]}" 1>/dev/null 2>/dev/null && \
        echo "${DEPENDENCIES[$dep]} already installed." || \
        install_dependency "${DEPENDENCIES[$dep]}" "${dep}"
done


if [ -z "${YES}" ];
then
    echo "=================================================================================="
    echo "WARNING: ALL DATA IN ${DEVICE} WILL BE LOST."
    read -r -p "Are you sure you want to format device:[${DEVICE}] with LUKS2 format? [y/N]:" INPUT_OPT
    echo "=================================================================================="
fi

if [ "${INPUT_OPT}" != "y" ];
then
    echo "Exiting ..."
    exit 0
fi

# Partition as luks
if [ -n "${LUKS_PASSWORD}" ];
then
    echo -n "${LUKS_PASSWORD}" | cryptsetup luksFormat --batch-mode --key-file - "${DEVICE}"
else
    cryptsetup luksFormat --batch-mode "${DEVICE}"
fi

# Open
echo "Opening device ${DEVICE} to format in EXT4 mode ..."
if [ -n "${LUKS_PASSWORD}" ];
then
    echo -n "${LUKS_PASSWORD}" | cryptsetup luksOpen "${DEVICE}" encrypted
else
    cryptsetup luksOpen "${DEVICE}" encrypted
fi

# Partition
mkfs.xfs /dev/mapper/encrypted

# Get UID (OF THE DEVICE !!!)
TRIMMED_DEVICE="${DEVICE//\/dev\//}"
UUID=$(lsblk --fs | grep "${TRIMMED_DEVICE}" | awk '{print $4}')

if [ -z "${UUID}" ];
then
    echo "WARNING: Unable to guess UUID"
    exit 0
fi

# Set crypttab as expected, with none, nofail
grep "luks-${UUID} UUID=${UUID} none nofail" /etc/crypttab 2>/dev/null 1>/dev/null || {
    echo "luks-${UUID} UUID=${UUID} none nofail" >> /etc/crypttab
}

test -d "${MOUNT_DIRECTORY}" || mkdir -p "${MOUNT_DIRECTORY}"

# Set fstab as expected, with next options:
grep "/dev/mapper/luks-${UUID} ${MOUNT_DIRECTORY} xfs  auto,nofail,noatime,rw,user 0 0"\
     /etc/fstab 2>/dev/null 1>/dev/null || {
    echo "/dev/mapper/luks-${UUID} ${MOUNT_DIRECTORY} xfs  auto,nofail,noatime,rw,user 0 0" \
         >> /etc/fstab
}
