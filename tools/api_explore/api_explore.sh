#!/bin/bash
# Copyright 2022 Sergio Arroutbi <sarroutb@redhat.com>
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

# Uncomment next line to dump verbose information in script execution:
# set -x

DEFAULT_K8SC="oc"
test -z "${K8SC}" && K8SC=${DEFAULT_K8SC}

DEFAULT_NAMESPACE="default"
test -z "${NAMESPACE}" && NAMESPACE=${DEFAULT_NAMESPACE}

function usage() {
  echo
  echo "ENDPOINT=tang-backend-tang TOKEN=\$(cat api_token.txt) NAMESPACE=ephemeral-rfymfc $0"
  echo
  exit "$2"
}

dumpInfo() {
    echo "K8SC:${K8SC}"
    echo "NAMESPACE:${NAMESPACE}"
    echo "TOKEN=${TOKEN}"
    echo "APISERVER=${APISERVER}"
    echo "ENDPOINT=${ENDPOINT}"
}

installDeps() {
    type jq 2>/dev/null 1>/dev/null || yum install -y jq 2>/dev/null 1>/dev/null
}

auth_curl() {
    curl -o - \
         --no-buffer \
         --header "Authorization: Bearer ${TOKEN}" \
         "${1}"
}

while getopts "h" arg
do
  case "${arg}" in
    h) usage "$0" 0
       ;;
    *) usage "$0" 1
       ;;
  esac
done


APISERVER=$(oc config view --minify -o jsonpath='{.clusters[*].cluster.server}')

# dumpInfo
installDeps

### Extract status of service
auth_curl "${APISERVER}/api/v1/namespaces/${NAMESPACE}/endpoints/${ENDPOINT}"

### Extract status of deployment (replica parse, for example)
auth_curl "${APISERVER}/apis/apps/v1/namespaces/${NAMESPACE}/deployments/${ENDPOINT}"

### Extract route like ENDPOINT and dump it
route=$(auth_curl "${APISERVER}/apis/route.openshift.io/v1/namespaces/${NAMESPACE}/routes" | grep "${ENDPOINT}-" | awk -F ":" {'print $2'} | tr -d '"' | tr -d ',' | tr -d ' ')
auth_curl "${APISERVER}/apis/route.openshift.io/v1/namespaces/${NAMESPACE}/routes/${route}"
