#!/bin/bash
#
# This script obtains information from DEE HMS to generate
# the netrc file required for CURL to connect automatically:
# machine env-ephemeral-rocidn-8hcomvf6.apps.c-rh-c-eph.8p0c.p1.openshiftapps.com login jdoe password raabbccddeeffgg

MACHINE=$(oc get routes | grep tang | awk '{print $2}' | tr -d " ")
KEYCLOAK_LOGIN_PASSWORD=$(bonfire namespace describe 2>&1 | grep 'login:'| awk -F ":" '{print $2}')
USER=$(echo "${KEYCLOAK_LOGIN_PASSWORD}" | awk -F "|" '{print $1}' | tr -d " ")
PASSWORD=$(echo "${KEYCLOAK_LOGIN_PASSWORD}" | awk -F "|" '{print $2}' | tr -d " ")

# machine env-ephemeral-rocidn-8hcomvf6.apps.c-rh-c-eph.8p0c.p1.openshiftapps.com login jdoe password raabbccddeeffgg
printf "machine %s login %s password %s\n" "${MACHINE}" "${USER}" "${PASSWORD}"
