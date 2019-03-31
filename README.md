# A utility to turn your blink camera on/off depending on time and on presence

This utility manages your Blink camera:
- turn on during night
- turn on of no-one is present

## Config

`setenv.sh` holds the config info:

```
#!/bin/bash

export BLINK_PWD=<your-blink-password>
export BLINK_EMAIL=<your-blink-email>
export CHECKIN_ENDPOINT=<the-endpoint-of-the-check-in-service>
export LOCATION=<the-location-you-monitor>
export NOTIFY_SLACK=<0|1>
export NOTIFY_MATTERMOST=<0|1>
export BOT_NAME=<some-name>
export BOT_CHANNEL=<some-channel>
export BOT_TOKEN=<slack-token>
export MM_WEBHOOK=<your-mattermost-incoming-webhook>

```

To schedule the utility to run regularly (in this example every 2 minutes) edit your crontab (`crontab -e`) and add:
```
*/2   *    *    *    *     cd <path-to-utility> && ./arm-when-noone-present.sh
```

## Dependencies

This utility depends on:
- the check-in service: https://github.com/asksven/home-automation-checkin-service
- `slack.phar` (https://github.com/cleentfaar/slack-cli/blob/master/README.md) if you want notifications to be sent to slack
