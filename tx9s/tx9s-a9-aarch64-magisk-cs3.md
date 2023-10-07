# tx9s-a9-aarch64-magisk-cs3.img

* Download from: https://www.dropbox.com/scl/fi/c7f338kk37b2y09jxzqlj/tx9s-a9-aarch64-magisk-cs3.zip?rlkey=hsz53rfmsi46yh9247iabe2fl&dl=1

* Based off of khadas_pie_AOSP_20200711_arm64_to_BB2_Pro
* / Increased to 3G in size.
* This image boots with a magisk-patched (with Magisk 26.3) boot partition.
* You only need to install the Magisk.v26.3.apk and go!
* Once you install Magisk, reboot and a policy will be added to grant shell root permission (su).

Automatic installations:

Network install:

If atv-installer.local.lan exists in DNS, the following url will be curled:

http://atv-intaller.local.lan/on-boot.tgz?mac=<mac-addr>&run-stage=N

Set up a webservice to serve a zip file or a tar.gz that contains a 'run.sh'
and anything else that goes with it. The file will be downloaded, extracted into
'/sdcard/.custom-install/.net-install' and the 'run.sh' will be run.

The 'mac' query param will contain the mac address of the device. The 'run-stage'
query param will contain whatever exists in '/sdcard/.custom-run-stage'. The value
is 0 when the file does not exist. You can use this to keep state on install when
reboots are involved. Just update that file.

USB install:

* If a usb drive is inserted and contains a 'boot.tgz', it will be extracted into
  '/sdcard/.custom-install/.usb-install' and the run.sh will be run.
* If a usb drive is inserted and contains a 'custom.sh', it will be executed on boot.
