#!/bin/bash

CURDIST=`lsb_release -cs`
export $CURDIST
export DIST=`lsb_release -cs`
if [ -e "/usr/share/ubukey" ]; then 
UBUKEYDIR="/usr/share/ubukey"
elif [ -e "/usr/local/share/ubukey" ]; then
UBUKEYDIR="/usr/local/share/ubukey"
else ## running .py
UBUKEYDIR="$(pwd)/../.."
fi

if [[ "`uname -m`" == "x86_64" ]]; then
	X64="true"
fi
