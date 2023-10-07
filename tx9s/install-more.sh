#!/system/bin/sh

#
# custom.sh will look for a 'more-install.sh' to run when it's done. 
# That is this file!
# 
# Add your custom commands in here if you want. Some examples (include all of
# these scripts on your USB drive or inside boot.tgz if you use them):

./set-hostname.sh 'my-hostname'
./set-timezone.sh 'Europe/London'
./set-ntp-server.sh uk.pool.ntp.org
#./install-atlas.sh
