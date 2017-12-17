#!/usr/bin/env bash

while read -r line
do

  TYPE="$(echo $line | jq -r '.type')"
  REASON="$(echo ${line} | jq -r '.reason')"
  MESSAGE="$(echo ${line} | jq -r '.message')"
  COMPONENT="$(echo ${line} | jq -r '.source.component')"
  OBJECT="$(echo ${line} | jq -r '.involvedObject.name')"
  NS="$(echo ${line} | jq -r '.involvedObject.namespace')"
  KIND="$(echo ${line} | jq -r '.involvedObject.kind')"


  if [ "$KIND" != "" ]; then
		EMOJI="kubernetes"
    if [ "$TYPE" != "Normal" ]; then
      EMOJI="this_is_fine"
    fi

    echo '{}' \
			| jq --arg CHANNEL "#$SLACK_CHANNEL" '. + { "channel": $CHANNEL }' \
			| jq --arg USERNAME "Openshift-$TYPE" '. + { "username": $USERNAME }' \
			| jq --arg EMOJI ":$EMOJI:" '. + { "emoji": $EMOJI }' \
			| jq '. + { "attachments": [{"fields":[], "title": "Openshift Event"}]}' \
			| jq --arg FIELD "Type" --arg VALUE "$TYPE" '.attachments[0].fields += [{"title": $FIELD, "value": $VALUE}]' \
			| jq --arg FIELD "Project" --arg VALUE "$NS" '.attachments[0].fields += [{"title": $FIELD, "value": $VALUE}]' \
			| jq --arg FIELD "Component" --arg VALUE "$COMPONENT" '.attachments[0].fields += [{"title": $FIELD, "value": $VALUE}]' \
			| jq --arg FIELD "Kind" --arg VALUE "$KIND" '.attachments[0].fields += [{"title": $FIELD, "value": $VALUE}]' \
			| jq --arg FIELD "Object" --arg VALUE "$OBJECT" '.attachments[0].fields += [{"title": $FIELD, "value": $VALUE}]' \
			| jq --arg FIELD "Reason" --arg VALUE "$REASON" '.attachments[0].fields += [{"title": $FIELD, "value": $VALUE}]' \
			| jq --arg FIELD "Message" --arg VALUE "$MESSAGE" '.attachments[0].fields += [{"title": $FIELD, "value": $VALUE}]' \
			| jq . > /tmp/to-slack.json


		LOG_MESSAGE="{\"openshiftEvent\":$line}"
		echo "$LOG_MESSAGE" | jq -c .

		if [ "$REASON" = "DesiredReplicasComputed" ]; then
			continue
		fi

		if [[ "$REASON" = "Pulled" ]]; then
			continue
		fi


		if [[ "$MESSAGE" =~ ^Created\ container\ with\ docker\ id* ]]; then
			continue
		fi

		if [[ "$MESSAGE" =~ ^Killing\ container\ with\ docker\ id* ]]; then
			continue
		fi

		if [ "$TYPE" = "Normal" ]; then
			continue
		fi

		if [[ -n "$SLACK_URL" ]]; then
			PAYLOAD="$(cat /tmp/to-slack.json)"
			curl -s -X POST --data-urlencode "payload=$PAYLOAD" $SLACK_URL > /dev/null
		fi

  fi
done < "${1:-/dev/stdin}"
