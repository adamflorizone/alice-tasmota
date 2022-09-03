#!/bin/bash
set -eu # missing vars or command errors will error script for safty

regex="Nmap scan report for (tasmota-[^ ]*)"

source ~/.ssh/tasmota.config

do_tasmota_cmd(){
   # https://tasmota.github.io/docs/Commands/#management
   # https://curl.se/docs/manpage.html#--data-urlencode
   # do_curl "http://${TASMOTA_USER}:${TASMOTA_PASSWORD}@${1}/cm?cmnd=${2}"

    cmnd=${@:2};
    url="${1}"
    [[ $url == "http"* ]] || url="http://${url}"

    curl --get --silent  \
    --header "Referer: ${url}/cs?"  \
    --data-urlencode "user=${TASMOTA_USER}" \
    --data-urlencode "password=${TASMOTA_PASSWORD}" \
    --data-urlencode "cmnd=${cmnd}" \
    "${url}/cm"
}

if [ -z "${1-}" ]; then
    echo 'usage: $0 [HOSTNAME|"192.168.1.*"]... [COMMAND|"do_config"]...'

    echo "Here is a list of local devices (192.168.1.*):"

    $0 192.168.1.* devicename
elif [[ "${2-}" == "do_config" ]]; then
    # Disable cross scripting!
    # ./alice-tasmota.sh 192.168.1.* SO128 0

    # Set all hostnames to default:
    # ./alice-tasmota.sh 192.168.1.* hostname "%s-%04d"

    # Set all timezones:
    # $0 $1 ${TASMOTA_TIMEZONE_CMD}

    # Set all passwords
    # $0 $1 WebPassword "${TASMOTA_PASSWORD}"

    # $0 $1 "Upgrade ${TASMOTA_UPGRADE_VERSION}"

    # $0 $1 status 1

    $0 $1 devicename

    $0 $1 status 2 
    # | jq .StatusFWR.Version

elif [[ "${1}" == *"*"* ]]; then
    # echo "Scanning network... $1 ${@:2}"
    #lines=$(cat ~/1.txt)
    lines=$(nmap -sn "$1")

    echo "["
    hostnames=( )
    while read line; do                                                                                                         
        [[ $line =~ $regex ]] &&  {
            echo "  {\"${BASH_REMATCH[1]}\": $(do_tasmota_cmd "${BASH_REMATCH[1]}" "${@:2}" || echo {})},"
        } &
     done <<< ${lines}

    wait
    echo "]"
else
    do_tasmota_cmd "$@"
fi



# TESTS with CONDITINAL WRITE:
# tasmota_secure_all
# tasmota_hostname_all

# 

# do_tasmota_cmd http://tasmota-ec2e08-3592 Hostname "%s-%04d"
# 


# WRITES:
# tasmota_set_timezone_all
# tasmota_upgrade_all