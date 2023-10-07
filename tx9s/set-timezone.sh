#!/system/bin/sh

timezone="$1"

if [ -z "$timezone" ]; then
    echo "Usage: $0 <timezone>"
    exit 1
fi

setprop persist.sys.timezone "$timezone"
