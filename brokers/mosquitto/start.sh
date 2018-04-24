#!/bin/sh

# This is unfortunately how we need to do it
# brew services cannot accept arguments
cp mosquitto.conf /usr/local/etc/mosquitto/
brew services run mosquitto
