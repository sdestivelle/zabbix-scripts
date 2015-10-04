#!/bin/bash

#       Notify by Boxcar
#       http://steve.destivelle.me
# See http://help.boxcar.io/support/solutions/articles/6000004813-how-to-send-a-notification-to-boxcar-for-ios-users for sounds notification list

curl -d "user_credentials=${1}" \
	-d "notification[title]=${2}" \
	-d "notification[long_message]=${3}" \
	-d "notification[sound]=up" \
	https://new.boxcar.io/api/notifications

echo -e
exit 0