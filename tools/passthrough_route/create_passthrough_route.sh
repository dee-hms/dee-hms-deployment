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

name="tang-iam-proxy-passthrough"
service="tang-iam-proxy-deployment"
port="8000"
verbose="0"

function usage() {
  echo
  echo "$0 [-n name] [-p port] [-s service] [-h] [-v]"
  echo
  echo "Examples:"
  echo "        $0 "
  echo
  echo "Options:"
  echo "        -n \"name\": name of the route to install (default:${name})"
  echo "        -p \"port\": port to redirect traffic (default:${port})"
  echo "        -s \"service\": service to deliver traffic matching route (default:${service})"
  echo "        -h: help"
  echo "        -v: verbose"
  echo
  exit "$2"
}

dumpVerbose() {
    if [ "${verbose}" == "1" ];
    then
        echo "${1}"    
    fi
}

while getopts "n:p:s:hv" arg
do
  case "${arg}" in
    n) name=${OPTARG}
       ;;
    p) port=${OPTARG}
       ;;
    s) service=${OPTARG}
       ;;
    h) usage "$0" 0
       ;;
    v) verbose="1"
       ;;
    *) usage "$0" 1
       ;;
  esac
done

if [ "${verbose}" == "1" ];
then
    echo "-----------------------------"    
    echo "name=${name}"
    echo "service=${service}"
    echo "port=${port}"
    echo "-----------------------------"    
fi

dumpVerbose "oc create route passthrough ${name} --service=${service} --port=${port}"
oc create route passthrough "${name}" --service="${service}" --port="${port}"
