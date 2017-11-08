#!/usr/bin/env bash

oc -n $NAMESPACE get events -w -o json | jq -c -M . | pipe-to-slack
