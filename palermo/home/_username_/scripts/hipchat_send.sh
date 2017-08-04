#!/bin/bash

# Set the ROOM_ID & AUTH_TOKEN variables below.
# Further instructions at https://www.hipchat.com/docs/apiv2/auth

ROOM_ID=2268444
AUTH_TOKEN=X86UXNY35rWLWRpR8CgZXId1xQtauNtYBSp8HB7l
MESSAGE=$1

curl -H "Content-Type: application/json" \
     -X POST \
     -d "{\"color\": \"purple\", \"message_format\": \"text\", \"message\": \"$MESSAGE\" }" \
     https://api.hipchat.com/v2/room/$ROOM_ID/notification?auth_token=$AUTH_TOKEN
