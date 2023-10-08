#!/system/bin/sh

#
# custom.sh will look for a 'more-install.sh' to run when it's done. 
# That is this file!
# 
# Add your custom commands in here if you want. Some examples (include all of
# these scripts on your USB drive or inside boot.tgz if you use them):

cd `dirname $0`

# Not sure this persist across reboot. Seem like they
# don't for me. So, it may be better to edit the below
# scripts and put the desired values in them.. and then
# mkdir -p /sdcard/.custom-init.d and copy them in there.
# If you're running at least cs5 image, then anything in
# that directory will run on boot.

sh ./set-hostname.sh 'my-hostname'
sh ./set-timezone.sh 'Europe/London'
sh ./set-ntp-server.sh uk.pool.ntp.org
#sh ./install-atlas.sh
