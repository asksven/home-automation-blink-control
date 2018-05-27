#!/bin/bash

source setenv.sh

now=$(date +"%Y-%m-%d %H:%M:%S")

# first we need to check who is at location
curl -k $CHECKIN_ENDPOINT/checkins/$LOCATION > temp2.json

RET=$?
if [ "$RET" -ne 0 ]; then
  echo $now error: curl returned $RET >> log
  exit 1
fi

PEOPLE_PRESENT=($(jq --raw-output '. | length' temp2.json))

echo $now people at $LOCATION $PEOPLE_PRESENT >> log

CURRENT_STATUS=`cat status`
OPERATION=""
MESSAGE=""

curl -H "Host: prod.immedia-semi.com" -H "Content-Type: application/json" --data-binary '{ "password" : "'$BLINK_PWD'", "client_specifier" : "iPhone 9.2 | 2.2 | 222", "email" : "'$BLINK_EMAIL'" }' --compressed https://rest.prod.immedia-semi.com/login > temp.json

TOKEN=($(jq --raw-output .authtoken.authtoken temp.json))
NETWORK=($(jq --raw-output '.networks | to_entries[0].key' temp.json))

# part of the REST endpoint for future calls is hidden in region
REGION=($(jq --raw-output '.region | to_entries[0].key' temp.json))

echo $TOKEN
echo $NETWORK
echo $REGION

HOUR=`date +%k%M`

echo $HOUR

if [ "$HOUR" -gt "0100" ]; then
  if [ "$HOUR" -lt "0800" ]; then
    # we are at night, arm
    echo $now we are at night, arm >> log
    OPERATION="arm"
    MESSAGE="Night-mode. Blink armed"
    curl -H "Host: prod.immedia-semi.com" -H "TOKEN_AUTH: $TOKEN" --data-binary --compressed https://rest.$REGION.immedia-semi.com/network/$NETWORK/arm
  else
    # we are at day
    if [ "$PEOPLE_PRESENT" = "0" ]; then
       echo $now no one is present, arm >> log
       OPERATION="arm"
       MESSAGE="No-one present. Blink armed"
        curl -H "Host: prod.immedia-semi.com" -H "TOKEN_AUTH: $TOKEN" --data-binary --compressed https://rest.$REGION.immedia-semi.com/network/$NETWORK/arm
    else
        echo $now someone is present, disarm >> log
        OPERATION="disarm"
        MESSAGE="Day-mode and someone is present. Blink disarmed"
        curl -H "Host: prod.immedia-semi.com" -H "TOKEN_AUTH: $TOKEN" --data-binary --compressed https://rest.$REGION.immedia-semi.com/network/$NETWORK/disarm
    fi

  fi
fi

if [ "$OPERATION" = "$CURRENT_STATUS" ]; then
  echo $now current state is $CURRENT_STATUS and target is $OPERATION. NOP >> log
else
  echo $now current state is $CURRENT_STATUS an target is $OPERATION. Applying $OPERATION >> log
  curl -H "Host: prod.immedia-semi.com" -H "TOKEN_AUTH: $TOKEN" --data-binary --compressed https://rest.$REGION.immedia-semi.com/network/$NETWORK/$OPERATION
  echo $OPERATION > status
  if [ "$NOTIFY" = "1" ]; then
  	slack.phar chat:post-message $BOT_CHANNEL "$MESSAGE" --username=$BOT_NAME --token=$BOT_TOKEN
  fi
fi  
    



