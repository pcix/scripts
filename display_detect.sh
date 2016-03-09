#!/bin/sh

#export Display for output
#export DISPLAY=:0.0

#some scripts for work
xrandr_command="/usr/bin/xrandr"
awk_command="/bin/awk"

#get max  resolution of connected devises
resolution_HDMI=`${xrandr_command} | $awk_command '/HDMI1 connected/ { getline; print  $1}'`

resolution_VGA=`${xrandr_command} | $awk_command '/VGA1 connected/ { getline; print  $1}'`

if [ -n "$resolution_VGA" ]; then

    notify-send "Displays connected"
    xrandr --output VGA1 --auto
    xrandr --output LVDS1 --off
    xrandr --output HDMI1 --auto --right-of VGA1

elif [ -n "$resolution_HDMI" ]; then

    notify-send "Display connected"
    xrandr --output HDMI1 --auto
    xrandr --output LVDS1 --auto --left-of HDMI1

else

    notify-send "Display disconnected"
    xrandr --output LVDS1 --auto --left-of HDMI1
    xrandr --output VGA1 --off
    xrandr --output HDMI1 --off
    xrandr --auto

fi

