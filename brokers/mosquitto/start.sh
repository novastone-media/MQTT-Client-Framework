#!/bin/sh

directory="${0%/*}";
cd "$directory"
/usr/local/opt/mosquitto/sbin/mosquitto -c mosquitto.conf &
