#!/bin/zsh

## Configuration variables ##
# allow the script to send notifications
if hash notify-send
then
    LCK_NOTIFICATIONS=true
else
    LCK_NOTIFICATIONS=false
fi

# path to the screenshot image
if [ -z $LCK_SOURCE_IMAGE ]
then
  LCK_SOURCE_IMAGE='/tmp/screenshot.png'
fi

# path to the blurred image
if [ -z $LCK_BLUR_IMAGE ]
then
  LCK_BLUR_IMAGE='/tmp/screenshot_blur.png'
fi

# path to the final image
if [ -z $LCK_FINAL_IMAGE ]
then
  LCK_FINAL_IMAGE='/tmp/screenshot_final.png'
fi

# additionnal image (e.g logo) centered on the final image
#LCK_LOGO_IMAGE=logo.png

if [ -f $HOME/.zscripts.conf ]
then
  source $HOME/.zscripts.conf
elif [[ ! -z $ZSCRIPTS_CONFIG_FILE && -f $ZSCRIPTS_CONFIG_FILE ]]
then
  source $ZSCRIPTS_CONFIG_FILE
fi

if [ $LCK_NOTIFICATIONS ]
then
  notify-send -u low 'Locking the screen...'
fi

scrot $LCK_SOURCE_IMAGE
convert $LCK_SOURCE_IMAGE -blur 0x5 $LCK_BLUR_IMAGE
if [[ ! -z $LCK_LOGO_IMAGE && -f $LCK_LOGO_IMAGE ]]
then
  convert $LCK_BLUR_IMAGE $LCK_LOGO_IMAGE -gravity center -composite -matte $LCK_FINAL_IMAGE
  i3lock -i $LCK_FINAL_IMAGE
else
  i3lock -i $LCK_BLUR_IMAGE
fi
