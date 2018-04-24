#!/bin/sh

# This is unfortunately how we need to do it
# brew services cannot accept arguments
directory="${0%/*}";
cp "$directory"/mosquitto.conf /usr/local/etc/mosquitto/
brew services run mosquitto
