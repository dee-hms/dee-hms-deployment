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
  echo "$0 -s source_partition -t to_device [-u] [-h] [-v]"
  echo
  echo "Examples:"
  echo "        $0 -s /dev/xvda1 -t /dev/xvdb"
  echo
  echo "Options:"
  echo "        -s \"source_partition\": device partition where current rootfs is"
  echo "        -t \"to_device\": device to format (mandatory) and copy current rootfs"
  echo "        -u: umount directories mounted by the script at exit"
  echo "        -h: help"
  echo "        -v: verbose"
  echo
  exit "$2"
}

while getopts "s:t:uhv" arg
do
  case "${arg}" in
    s) SOURCE_PARTITION=${OPTARG}
       ;;
    t) TO_DEVICE=${OPTARG}
       ;;
    u) UMOUNT="Y"
       ;;
    h) usage "$0" 0
       ;;
    v) set -x
       ;;
    *) usage "$0" 1
       ;;
  esac
done

####### Install dependencies
sudo dnf install -y rsync

####### Format TO DEVICE
(
echo n
echo
echo
echo
echo
echo w
) | fdisk "${TO_DEVICE}"
# PART can be 1 or p1
devpart=$(sudo fdisk -l "${TO_DEVICE}" | grep "${TO_DEVICE}1" | awk '{print $1}')
sudo mkfs.xfs -f "${devpart}"

###### Mount everything and rsync
mkdir -p /mnt/switchrootfs/rootfs /mnt/switchrootfs/newrootfs
mount "${SOURCE_PARTITION}" /mnt/switchrootfs/rootfs
mount "${devpart}" /mnt/switchrootfs/newrootfs
rsync -zahP /mnt/switchrootfs/rootfs/* /mnt/switchrootfs/newrootfs

##### PENDING!!! fstab and grubby

##### Umount
if [ "${UMOUNT}" == "Y" ];
then
  umount /mnt/switchrootfs/rootfs
  umount /mnt/switchrootfs/newrootfs
fi

