#!/bin/bash
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
DEPENDENCIES=(expect)
PKG_MGR="dnf"

usage() {
    echo
    echo "$1 -c <configFile> -d <dbHost:dbUser:dbPassword> -t <tang_podname> [-h] [-v]"
    echo
    exit "$2"
}

usage_message() {
    echo
    echo "$2"
    usage "$1" "$3"
}

installDependency() {
    echo "Installing dependency[${2}]: ${1}"
    ${PKG_MGR} install -y "${1}" 2>/dev/null 1>/dev/null
}

checkParams() {
    test -z "${dbhost}"       && usage_message "$0" "Please, provide database host" 1
    test -z "${dbuser}"       && usage_message "$0" "Please, provide database user" 2
    test -z "${dbpassword}"   && usage_message "$0" "Please, provide database password" 3
    test -z "${tang_podname}" && usage_message "$0" "Please, provide tang pod name" 4
    test -z "${config_file}"  && usage_message "$0" "Please, provide configuration file" 5
    test -f "${config_file}"  || usage_message "$0" "Please, provide existing configuration file" 6
}

detectPackageManager() {
    which apt 2>/dev/null 1>/dev/null && PKG_MGR="apt"
}

dumpInfo() {
    if [ -n "${verbose}" ]; then
        echo "---------------------------------------"
        echo "configuration_file:[${config_file}]"
        echo "dbhost_user_password:[${dbhost_user_password}]"
        echo "dbhost:${dbhost}"
        echo "dbuser:${dbuser}"
        echo "dbpassword:${dbpassword}"
        echo "tang_podname:${tang_podname}"
        echo "---------------------------------------"
    fi
}

installDependencies() {
    for ((dep=0; dep<${#DEPENDENCIES[*]}; dep++))
    do
        installDependency "${DEPENDENCIES[$dep]}" "${dep}"
    done
}

parseDbUserPassword() {
    dbhost=$(echo "${dbhost_user_password}" | awk -F ':' '{print $1}')
    export dbhost
    dbuser=$(echo "${dbhost_user_password}" | awk -F ':' '{print $2}')
    export dbuser
    dbpassword=$(echo "${dbhost_user_password}" | awk -F ':' '{print $3}')
    export dbpasword
}

# Check executed as root
ID=$(id -u)
if [ "${ID}" != "0" ];
then
    echo
    echo "This script has to be executed as root user or via sudo"
    echo
    exit 1
fi

while getopts "c:d:u:p:t:hv" arg
do
    case "${arg}" in
        c) export config_file=${OPTARG}
           ;;
        d) export dbhost_user_password=${OPTARG}
           ;;
        h) usage "$0" 0
           ;;
        t) export tang_podname=${OPTARG}
           ;;
        u) export httpuser_password=${OPTARG}
           ;;
        v) export verbose=1
           ;;
        *) usage "$0" 1
           ;;
    esac
done

parseDbUserPassword
dumpInfo
checkParams
detectPackageManager
installDependencies
