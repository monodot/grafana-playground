#!/bin/sh
sed -i "s/__HOSTNAME__/${HOSTNAME}/g" /etc/agent/agent.yaml
