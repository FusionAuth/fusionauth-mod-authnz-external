#!/bin/bash

#
# FusionAuth External Authentication for Apache HTTP Server
#

error() {
  echo "$@" 1>&2
}

# Default configuration file
CONFIG=/usr/local/fusionauth/config/fusionauth_mod.properties

if [ ! -f "$CONFIG" ]; then
  error "Unable to find the configuration file [${CONFIG}]"
  exit 1
fi

value=$(cat ${CONFIG} | grep "^fusionauth.url" | awk -F'=' '{print $2}')
if [ -n "$value" ]; then
  URL="$value"
else
  error "Unable to find the configuration for [fusionauth.url]"
  exit 1
fi

value=$(cat ${CONFIG} | grep "^fusionauth.network_interface" | awk -F'=' '{print $2}')
if [ -n "$value" ]; then
  INTERFACE="$value"
else
  INTERFACE="eth0"
fi

# The application Id is required as the first parameter
if [[ $# -lt 1 ]]; then
  echo "The Application Id is required as the first parameter."
  exit 1
fi

APPLICATION_ID=$1
shift
# Take the remaining arguments as the role, it may contain a space.
ROLE="$@"

read -n1024 USER
read -n1024 PASSWORD

IP_ADDR=`ifconfig ${INTERFACE} | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`

# Authenticate and verify role
# Call the Login API and parse the token (access token) in the response.
TOKEN=$(/usr/bin/curl -s -X POST \
       -H 'Accept: application/json' \
       -H 'Content-Type: application/json' \
       -H "Authorization: ${API_KEY}" -d \
       "{\"applicationId\": \"$APPLICATION_ID\", \"loginId\": \"$USER\", \"password\": \"$PASSWORD\", \"ipAddress\": \"$IP_ADDR\"}" \
       ${URL}/api/login \
       | jq -j '.token')

STATUS=`echo $?`
if [ ${STATUS} -ne 0 ]; then
  exit ${STATUS}
fi

# Call the Userinfo endpoint to verify the Access Token and retrieve user claims
RESULT=$(/usr/bin/curl -s -X GET -H "Authorization: Bearer ${TOKEN}" ${URL}/oauth2/userinfo)
STATUS=`echo $?`
if [ ${STATUS} -ne 0 ]; then
  exit ${STATUS}
fi

APP_ID=$(echo ${RESULT} | jq -j '.applicationId')
if [ "${APP_ID}" != "${APPLICATION_ID}" ]; then
  exit 1
fi

# If a role was requested, verify the value exists in the roles claim.
if [ -n "$ROLE" ]; then
  HAS_ROLE=$(echo ${RESULT} | jq ".roles|any(. == \"${ROLE}\")")
  if [ ${HAS_ROLE} == "false" ]; then
    exit 1
  fi
fi

