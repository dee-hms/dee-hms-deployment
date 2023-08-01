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
    echo "$1 -c <configFile> -d <dbHost:dbUser:dbPassword> [-t tang_podname (will be guessed if not provided)] [-k k8s_client (oc by default)] [-h] [-v] "
    echo
    exit "$2"
}

usageMessage() {
    echo
    echo "$2"
    usage "$1" "$3"
}

installDependency() {
    dumpVerbose "Installing dependency[${2}]: ${1}"
    ${PKG_MGR} install -y "${1}" 2>/dev/null 1>/dev/null
}

guessPodName() {
    tang_podname=$("${k8s_client}" get pods | grep tang-backend | awk '{print $1}')
    export tang_podname
}

checkParams() {
    test -z "${dbhost}"       && usageMessage "$0" "Please, provide database host" 1
    test -z "${dbuser}"       && usageMessage "$0" "Please, provide database user" 2
    test -z "${dbpassword}"   && usageMessage "$0" "Please, provide database password" 3
    test -z "${config_file}"  && usageMessage "$0" "Please, provide configuration file" 5
    test -f "${config_file}"  || usageMessage "$0" "Please, provide existing configuration file" 6
    test -z "${k8s_client}"   && export k8s_client="oc"
    test -z "${tang_podname}" && guessPodName
}

detectPackageManager() {
    which apt 2>/dev/null 1>/dev/null && PKG_MGR="apt"
}

dumpVerbose() {
    if [ -n "${verbose}" ]; then
        echo "${1}"
    fi
}

dumpInfo() {
    if [ -n "${verbose}" ]; then
        echo "---------------------------------------------------------"
        echo "configuration_file:[${config_file}]"
        echo "dbhost_user_password:[${dbhost_user_password}]"
        echo "dbhost:${dbhost}"
        echo "dbuser:${dbuser}"
        echo "dbpassword:${dbpassword}"
        echo "tang_podname:${tang_podname}"
        echo "---------------------------------------------------------"
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

databaseCommand() {
    echo "$1" | mysql --host="${dbhost}" --user="${dbuser}" --password="${dbpassword}"
}

databaseCommandTangBindings() {
    databaseCommand "USE tang_bindings; $1"
}

createDatabase() {
    databaseCommand "CREATE DATABASE tang_bindings;" 2>/dev/null 1>/dev/null
    databaseCommand "USE tang_bindings; create table bindings (spiffe_id VARCHAR(255) NOT NULL, tang_workspace VARCHAR(255) NOT NULL);" 2>/dev/null 1>/dev/null
}

insertEntries() {
    local workspace
    local spiffe_id
    while read -r line;
    do
        workspace=$(echo "${line}" | awk -F ',' '{print $1}')
        spiffe_id=$(echo "${line}" | awk -F ',' '{print $2}')
        echo "Inserting entry:workspace:[${workspace}];spire_id:[${spiffe_id}]"
        databaseCommandTangBindings "insert into bindings (tang_workspace, spiffe_id) values ('${workspace}', '${spiffe_id}');"
        "${k8s_client}" exec -i "${tang_podname}" -- /bin/bash -s <<EOF
#!/bin/bash
echo "${workspace},/var/db/${workspace}" >> /etc/socat-tang-filter.csv
EOF
    done< "${config_file}"
}

while getopts "c:d:k:p:t:hv" arg
do
    case "${arg}" in
        c) export config_file=${OPTARG}
           ;;
        d) export dbhost_user_password=${OPTARG}
           ;;
        h) usage "$0" 0
           ;;
        k) export k8s_client=${OPTARG}
           ;;
        t) export tang_podname=${OPTARG}
           ;;
        v) export verbose=1
           ;;
        *) usage "$0" 1
           ;;
    esac
done

parseDbUserPassword
checkParams
dumpInfo
detectPackageManager
installDependencies
createDatabase
insertEntries
