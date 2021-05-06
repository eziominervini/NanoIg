#!/bin/bash

DIR="`dirname \"$0\"`"              # relative
DIR="`( cd \"$MY_PATH\" && pwd )`"  # absolutized and normalized
if [ -z "$MY_PATH" ] ; then
  exit 1 
fi
echo "$MY_PATH"

DIR= "`dirname \"$0\"`"

echo "$DIR"


sed -i 's/\/NanoIgset.py//g' "$DIR"/bashexec.txt

sed -i 's,//,/,g' "$DIR"/bashexec.txt
