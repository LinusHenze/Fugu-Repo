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
    
    # Rename snapshot on /, if required
    # Thanks to @brandonplank (https://github.com/brandonplank)!
    # See https://github.com/LinusHenze/Fugu/issues/7
    echo "$EXE: Renaming snapshot..."
    SNAPSHOT=$(/usr/bin/snappy -l -f / | /usr/bin/grep com.apple.os.update)||SNAPSHOT=""
    if [ ! -z "$SNAPSHOT" ]
    then
        NEWNAME=$(/bin/echo "$SNAPSHOT" | /usr/bin/sed -e "s/com.apple.os.update/Fugu.orig.fs.backup/")
        /usr/bin/snappy -f / -r "$SNAPSHOT" -t "$NEWNAME"
    fi
    
    echo "$EXE: Generating SSH Host Keys..."
    /usr/bin/ssh-keygen -A
    
    echo "$EXE: Installing firmware package..."
    /bin/bash /usr/libexec/cydia/firmware.sh
    
    echo "$EXE: Installing debs..."
    cd /debs
    /usr/bin/dpkg -i *
    
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
    
    echo "$EXE: Killing cfprefsd..."
    /usr/bin/killall -9 cfprefsd
    
    echo "$EXE: Respringing..."
    /usr/bin/killall -SIGTERM SpringBoard
    
    echo "$EXE: Installation completed"
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
