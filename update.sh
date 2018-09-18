#!/usr/bin/zsh

## Configuration variables ##
# allow the script to send notifications
if hash notify-send
then
  UPD_NOTIFICATIONS=true
else
  UPD_NOTIFICATIONS=false
fi

# path to the source file to check
if [ -z $UPD_SOURCE_FILE ]
then
  UPD_SOURCE_FILE=$HOME/.config/autoUpdateList
fi

if [ -f $HOME/.zscripts.conf ]
then
  source $HOME/.zscripts.conf
elif [[ ! -z $ZSCRIPTS_CONFIG_FILE && -f $ZSCRIPTS_CONFIG_FILE ]]
then
  source $ZSCRIPTS_CONFIG_FILE
fi


# make display available
if [ $UPD_NOTIFICATIONS ]
then
  DBUS_SESSION_BUS_ADDRESS=$(ps -u $(id -u) -o pid= | while read pid; do
    cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep '^DBUS_SESSION_BUS_ADDRESS';
  done | sort -u | grep user | grep -v ,)
  export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS#*=}

  notify-send -u low 'System' 'Checking source packages...'
fi

packageList=''

if [ ! -f $UPD_SOURCE_FILE ]
then
  echo "The UPD_SOURCE_FILE: $UPD_SOURCE_FILE does not exists"
  exit 1
fi

for line in $(cat $UPD_SOURCE_FILE)
do
  source_dir=${line%\#*}
  method='master'
  if [[ ${line} = *"#"* ]]
  then
    method=${line#*\#}
  fi

  echo "source: $source_dir, method: $method"

  # This tricks allow to use environement variable in UPD_SOURCE_FILE
  # but represent a security breach as every line would be evaluated
  source_dir=`eval "echo $source_dir"`
  cd $source_dir

  packageName=${PWD##*/}

  if [ ! -d '.git' ]
  then
    echo 'Error: not a git repository.'
    continue
  fi

  # update tracking refs
  ret=$(git remote update)
  if [ $? -ne '0' ]
  then
    echo 'Error: problem during refs tracking.'
    continue
  fi

  # check if updates available
  if [[ $method = "master" || $method = "branch" ]]
  then
    # master sentinel
    ret=$(git rev-parse --abbrev-ref HEAD)
    if [[ $method = "master" && $ret != 'master' ]]
    then
      echo 'Error: not on master.'
      continue
    fi

    ret=$(git status -uno)
    if [[ $ret = *"behind"* && $ret = *"fast-forward"* ]]
    then
      packageList+=$packageName' '
    fi
  elif [[ $method = "tag" ]]
  then
    lastTag=$(git describe --tags `git rev-list --tags --max-count=1`)
    curTag=$(git describe --tags)
    if [[ $lastTag != $curTag ]]
    then
      packageList+=$packageName' '
    fi
  elif [[ $method = "aur" || -f 'PKGBUILD' ]] # aur repo are automatically detected
  then
    if [ -f 'PKGBUILD' ]
    then
      pkgname=$(makepkg --printsrcinfo | grep 'pkgname =' | cut -f 2 -d =)
      # force method to be aur if detected
      method="aur"

      # AUR: updated but check if installed
      ret=$(pacman -Q ${pkgname/ /})
      if [ $? -ne '0' ]
      then
        packageList+=$packageName' '
      fi
    else
      echo "Error: No PKGBUILD file in an aur repository"
    fi
  fi
done

toNotify=$(echo $packageList | wc -w)
if [[ $toNotify -gt '0' && $UPD_NOTIFICATIONS ]]
then
  notify-send -u normal 'System update' 'Custom Packages: '$packageList
fi

nbupdates=$(checkupdates | wc -l)
if [[ $nbupdates -gt '0' && $UPD_NOTIFICATIONS  ]]
then
  notify-send -u normal 'System update' 'Base packages: '$nbupdates
fi
