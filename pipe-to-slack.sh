#!/bin/sh

while read line
do

  LAST_TS="$(echo $line | jq -r '.lastTimestamp')"
  if [ -z "$LAST_TS" ]; then
    continue
  fi

  LAST_TS_TS="$(date +%s -d$LAST_TS)"
  NOW_TS="$(date +%s)"
  SECONDS_AGO="$(( $NOW_TS - $LAST_TS_TS ))"

  if [ "$SECONDS_AGO" -gt 600 ]; then
    continue
  fi

  TYPE="$(echo $line | jq -r '.type')"
  REASON="$(echo ${line} | jq -r '.reason')"
  MESSAGE="$(echo ${line} | jq -r '.message')"
  COMPONENT="$(echo ${line} | jq -r '.source.component')"
  OBJECT="$(echo ${line} | jq -r '.involvedObject.name')"
  NS="$(echo ${line} | jq -r '.involvedObject.namespace')"
  KIND="$(echo ${line} | jq -r '.involvedObject.kind')"

  if [ "$REASON" = "DesiredReplicasComputed" ]; then
    continue
  fi



  if [ "$KIND" != "" ]; then
		EMOJI="kubernetes"
    if [ "$TYPE" != "Normal" ]; then
      EMOJI="this_is_fine"
    fi
    OUT="> $TYPE\n> Project: \`${NS}\`\n> Object: \`$KIND/$OBJECT\`\n> Component: \`$COMPONENT\`\n> Reasons: $REASON\n> Message: $MESSAGE"
    curl -s -X POST --data-urlencode "payload={\"channel\": \"#$SLACK_CHANNEL\", \"username\": \"openshift-$TYPE\", \"text\": \"$OUT\", \"icon_emoji\": \":$EMOJI:\"}" $SLACK_URL > /dev/null
    echo $line | jq -c .
  fi
done < "${1:-/dev/stdin}"
