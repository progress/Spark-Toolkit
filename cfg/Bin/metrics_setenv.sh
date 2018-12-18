#!/bin/sh

# Set the name of the ABLApp which you want to monitor.
ABLAPP_NAME=oepas1
export ABLAPP_NAME

# Set the URL of the server where we can reach the OEManager webapp.
INSTANCE_URI=http://localhost:8810
export INSTANCE_URI

# Set the name of the config file to use at runtime.
METRICS_CONFIG=metrics_config.json
export METRICS_CONFIG
