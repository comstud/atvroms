# WHAT DO I DO WITH THIS?

## DESCRIPTION

This is an image that contains a magisk-patched boot image (made with Magisk 26.3). It is based off of the `khadas_pie_AOSP_20200711_arm64_to_BB2_Pro image`, which we've found to work for S912 AMLOGIC cpus, as are found in Tanix TX9S and some iHomelife boxes. Maybe only works with the DDR2 RAM based models?

Also included here is a custom.sh script that you can (and should) use immediately after flashing the image. (see below.)

It does the following things:

* Installs the Magisk apk.
* Starts Magisk in order to finish its install, taps the OK on the screen, and reboots (and continues on next step).
* Enables Magisk zygisk and denylist
* Installs integrityfix.zip (magisk module)
* The image itself ensures you can 'su' from shell, but this script also does it.
* Installs pokemongo.apk if it exists.
* Installs integritychecker.apk if it exists.
* Adds pokemongo to denylist.
* Attempts to run a 'more-install.sh' script if it exists.

## FLASHING THE IMAGE

* Grab the cs5 image zip file from: [This place here](https://www.dropbox.com/scl/fi/kwqdxhbisek3r68xv6vyp/tx9s-a9-aarch64-magisk-cs5.zip?rlkey=kqu6v122e8c1hxulwewtaql35&dl=1)
* Unzip it, and flash the image to your ATV using the amlogic burn tool.
* Read the .md first, if you want.

## PREPARE YOUR SOFTWARE

Gather the following (rename them, if their names do not match):

* The custom.sh from where you got this file.
* Grab integrityfix.zip (from where you got this file or elsewhere. do not use 9.0, it is busted.)
* Get your favorite arm64-v8a verison of pokemongo and rename the apk to pokemongo.apk.

OPTIONAL:

* Grab integritychecker.apk (from where you got this file or elsewhere.)
* Make (or use/edit the one found where you got this file) a 'install-more.sh'
* You may put whatever commands you want in there. It will run at the end of 'custom.sh' as root.
* If running cs5 or newer, you can mkdir /sdcard/.custom-init.d and copy *.sh into there and they will run on boot.

## USING USB DRIVE METHOD #1

* Find a FAT32 formatted usb drive.
* Copy the custom.sh and everything you gathered above put into the USB drive's root folder/directory.
* Insert USB drive into ATV in USB slot furthest from ethernet port (for Tanix, anyway).
* Insert network cable.
* Give power to the ATV and if you connect the HDMI, watch it work.
* Check progress via adb.. The log file is at /sdcard/.custom-install/install.log
* Takes 5 minutes or so?

## USING USB DRIVE METHOD #2

* Rename custom.sh to run.sh
* zip or tar (or tar+gzip) the run.sh and the other files you gathered above. Name the zip/tar as 'boot.tgz'.
* The files should be in the root in the zip/tar, not in a subdirectory/subfolder.
* Follow the procedure in USB DRIVE METHOD #1 above, *EXCEPT* only copy the boot.tgz to the root of the USB drive.

## NETWORK INSTALL

Say what? Yes, that's right. Set up a nginx/webserver/whatever and serve the boot.tgz mentioned above.

I won't provide instructions as this is for the more techy folks who probably already can figure this out.
There's also quite a number of ways to do this. But here's the information you will need, and some hints:

* The image will curl this address: `http://atv-installer.local.lan/boot.tgz?mac=<mac-addr>&run_stage=x`
* It expects a successful HTTP response code and a file attachment. The file attachment can be named anything.
* There's more info about this in the image's .md file. I suggest reading that.

Basic steps to setup:

* Create a DNS entry for 'atv-installer.local.lan' and point it at.. nginx or a webserver, or something.
* Make sure you have a handler for /boot.tgz and have it serve up your boot.tgz
* If you're using something that can also filter on query params, you can do something with 'mac', if you want to serve different boot.tgz files to different devices.
* Have fun.
* Just plug in the ATV to ethernet and power it on.

## THAT'S IT. GO NUTS.
