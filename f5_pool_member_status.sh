#!/bin/bash

# Variables Passed As Arguments
F5_USER=$1
F5_HOST=$2
F5_PASS=$(<password.txt)
POOL=$3

# Function to get the status of a virtual address
get_pool_member_status() {
    curl -sk -u $F5_USER:$F5_PASS \
    -H "Content-Type: application/json" \
    -X GET "https://$F5_HOST/mgmt/tm/ltm/pool/~Common~$POOL/members/stats"
}

get_pool_member_status | jq '.entries[].nestedStats.entries | ."addr", ."sessionStatus", ."status.availabilityState", ."status.enabledState"' | jq '.description' | tr -d '"' >> output.txt

input="output.txt"

while read ADDR; read SESSION; read AVAILABILITY; read STATE;

do
 jq -nc \
  --arg lb_host "$F5_HOST"\
  --arg pool "$POOL" \
  --arg addr "$ADDR" \
  --arg session "$SESSION" \
  --arg availability "$AVAILABILITY" \
  --arg state "$STATE" \
  '{
     "LB HOST": $lb_host,
         "POOL": $pool,
     "BACKEND_SERVER_IP": $addr,
     "SESSION_STATUS": $session,
     "AVAILBILITY_STATUS": $availability,
         "STATE": $state
   }' >> final_output.txt
done < $input
rm output.txt
