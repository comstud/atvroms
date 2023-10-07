#!/system/bin/sh

ntp_server="$1"

if [ -z "$ntp_server" ]; then
    echo "Usage: $0 <ntp-server>"
    exit 1
fi

settings put global ntp_server "$ntp_server"
