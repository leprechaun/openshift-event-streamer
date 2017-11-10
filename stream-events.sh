#!/usr/bin/env bash

while true; do
	oc -n $NAMESPACE get events -w -o json | jq -c -M . | pipe-to-slack
	sleep 30
done
