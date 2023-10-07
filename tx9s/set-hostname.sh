#!/system/bin/sh

hostname="$1"

if [ -z "$hostname" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

setprop net.hostname "$hostname"
