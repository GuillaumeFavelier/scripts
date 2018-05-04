#!/bin/zsh

## Configuration variables ##
# allow the script to send notifications
g_enableNotification='yes'

# path to the screenshot image
lck_sourceImage='/tmp/screenshot.png'

# path to the blurred image
lck_blurImage='/tmp/screenshot_blur.png'

# path to the final image
lck_finalImage='/tmp/screenshot_final.png'

# additionnal image (e.g logo) centered on the final image
#lck_logoImage=logo.png

if [ -f $HOME/.zscripts.conf ]
then
  source $HOME/.zscripts.conf
elif [ -f $ZSCRIPTS_CONFIG_FILE ]
then
  source $ZSCRIPTS_CONFIG_FILE
fi

if [ $g_enableNotification = 'yes' ]
then
  notify-send -u low 'Locking the screen...'
fi

scrot $lck_sourceImage
convert $lck_sourceImage -blur 0x5 $lck_blurImage
if [[ $lck_logoImage != "" ]] && [[ -f $lck_logoImage ]]
then
  convert $lck_blurImage $lck_logoImage -gravity center -composite -matte $lck_finalImage
  i3lock -i $lck_finalImage
else
  i3lock -i $lck_blurImage
fi
