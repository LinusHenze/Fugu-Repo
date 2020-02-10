#!/bin/bash

set -e

EXE=$(basename "$0")

if [ $# -ne 1 ]; then
    echo "Usage: $EXE <noRespring/respringNow>"
    exit -5
fi

if [ "$1" = "noRespring" ]; then
    # Stage 1
    echo "$EXE: Stage 1, not respringing"
    
    echo "$EXE: Generating SSH Host Keys..."
    /usr/bin/ssh-keygen -A
    
    echo "$EXE: Installing firmware package..."
    /bin/bash /usr/libexec/cydia/firmware.sh
    
    echo "$EXE: Installing debs..."
    cd /debs
    /usr/bin/dpkg -i *
    
    echo "$EXE: Adding chimera repo..."
    echo "deb https://repo.chimera.sh/ ./" > /etc/apt/sources.list.d/chimera.list
    
    echo "$EXE: Launching services..."
    cd /Library/LaunchDaemons
    /sbin/launchctl load *.plist
    
    echo "$EXE: Running uicache..."
    /usr/bin/uicache --path /Applications/Sileo.app
    
    echo "$EXE: Stage 1 done"
    
    exit 0
elif [ "$1" = "respringNow" ]; then
    # Stage 2
    echo "$EXE: Stage 2, will respring"
    
    echo "$EXE: Launching substitute..."
    /etc/rc.d/substitute
    
    /bin/rm /System/Library/Substitute/DynamicLibraries/Unsandbox.dylib
    
    echo "$EXE: Injecting Unsandbox..."
    PID=$(/sbin/launchctl list com.apple.cfprefsd.xpc.daemon | /usr/bin/grep PID | /usr/bin/xargs | /bin/sed -e "s/PID = //" -e "s/;//")
    # /System/Library/Substitute/Helpers/dlopen_in_pid $PID /System/Library/Substitute/Helpers/bundle-loader.dylib &
    
    sleep 1
    
    echo "$EXE: Respringing..."
    /usr/bin/killall -SIGTERM SpringBoard
    
    echo "$EXE: Install completed"
    echo "$EXE: Cleaning up..."
    /bin/rm -rf /debs /bootstrap.tar /install.sh
    
    echo "$EXE: Creating /.Fugu_installed ..."
    /usr/bin/touch /.Fugu_installed
    
    echo "$EXE: Stage 2 done"
    exit 0
else
    # WTF?
    echo "$EXE: Unknow argument $1"
    exit -5
fi
