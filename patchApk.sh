#!/bin/bash
set -e

# Patch the apk
objection patchapk -s base.apk -c config.json -m manifest.xml -l _agent.js --architecture armeabi-v7a -V 16.7.19
#objection patchapk -s base.apk -N -m manifest.xml --architecture armeabi-v7a

if [ ! -f ./base.objection.apk ]; then
  echo "Error: objection did not produce ./base.objection.apk. Aborting." >&2
  exit 1
fi

cp ./base.objection.apk ./patched.apk
rm -f ./base.objection.apk
