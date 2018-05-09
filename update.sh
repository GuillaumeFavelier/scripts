#!/usr/bin/zsh

## Configuration variables ##
# allow the script to send notifications
if hash notify-send
then
    UPD_NOTIFICATIONS=true
else
    UPD_NOTIFICATIONS=false
fi

# duration of the lock in seconds
if [ -z $UPD_WAITINGTIME ]
then
    UPD_WAITINGTIME='300'
fi

# path to the lock file, during locking
# no update installation will be done
if [ -z $UPD_LOCKFILE ]
then
    UPD_LOCKFILE='/tmp/auto_update.lock'
fi

# path to the update checking log
if [ -z $UPD_LOGFILE ]
then
    UPD_LOGFILE='/tmp/auto_update.log'
fi

# path to the source directory to check
if [ -z $UPD_SOURCEFILE ]
then
    UPD_SOURCEFILE=$HOME/.config/autoUpdateList
fi

# path to the file containing a list of
# sources to exclude
#upd_excludeFile=$HOME'/.exclude'

if [ -f $HOME/.zscripts.conf ]
then
  source $HOME/.zscripts.conf
elif [[ -z $ZSCRIPTS_CONFIG_FILE && -f $ZSCRIPTS_CONFIG_FILE ]]
then
  source $ZSCRIPTS_CONFIG_FILE
fi

if [[ $# -gt '0' && $1 = '--scan' ]]
then
  ## Start update detection system ##

  # make display available
  if [ $UPD_NOTIFICATIONS ]
  then
    export DISPLAY=$(ps -u $(id -u) -o pid= | \
      while read pid; do
        cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep '^DISPLAY=:'
      done | grep -o ':[0-9]*' | sort -u)

      notify-send -u low 'System' 'Checking source packages...'
    fi

    packageList=''

    if [ ! -f $UPD_SOURCEFILE ]
    then
        echo "The UPD_SOURCEFILE: $UPD_SOURCEFILE does not exists"
        exit 1
    fi

    for line in $(cat $UPD_SOURCEFILE)
    do
      current=$line
      method=''

      echo $current

      # This tricks allow to use environement variable in UPD_SOURCEFILE
      # but represent a security breach as every line would be evaluated
      current=`eval "echo $current"`
      cd $current

      if [ ! -d '.git' ]
      then
        if [ -d 'source' ]
        then
          current=$current'/source'
          cd ./source
        else
          echo 'Error: neither a source directory or a git repository.'
          continue
        fi
      fi

      # update tracking refs
      ret=$(git remote update)
      if [ $? -ne '0' ]
      then
        echo 'Error: problem during refs tracking.'
        continue
      fi

      ret=$(git rev-parse --abbrev-ref HEAD)
      if [ $ret != 'master' ]
      then
        echo 'Error: not on master.'
        continue
      fi

      # check if updates available
      ret=$(git status -uno)

      if [[ $ret = *"behind"* ]] && [[ $ret = *"fast-forward"* ]]
      then
        packageList+=$i' '
        echo $current
        echo $UPD_LOGFILE
        echo $current >> $UPD_LOGFILE
      elif [ -f 'PKGBUILD' ]
      then
        pkgname=$(makepkg --printsrcinfo | grep 'pkgname =' | cut -f 2 -d =)

        # AUR: updated but check if installed
        ret=$(pacman -Q ${pkgname/ /})
        if [ $? -ne '0' ]
        then
          packageList+=$i' '
          echo $current >> $UPD_LOGFILE
        fi
      fi
    done

    toNotify=$(wc -l $UPD_LOGFILE | cut -f1 -d \  )
    if [[ $toNotify -gt '0' && $UPD_NOTIFICATIONS ]]
    then
      notify-send -u normal 'System update' 'Custom Packages: '$packageList
    fi

    nbupdates=$(checkupdates | wc -l)
    if [[ $nbupdates -gt '0' && $UPD_NOTIFICATIONS  ]]
    then
      notify-send -u normal 'System update' 'Base packages: '$nbupdates
    fi
  else
    # detect if being sourced
    if [[ $_ != $0 && $_ != $SHELL ]]
    then
      ## Start auto-update system ##
      if [[ ! -f $UPD_LOCKFILE ]] && [[ -f $UPD_LOGFILE ]]
      then
        packages=$(cat $UPD_LOGFILE 2> /dev/null)
        numberOfUpdates=$(wc -l $UPD_LOGFILE 2> /dev/null | cut -f1 -d\ )
        if [ $numberOfUpdates -ge 1 ]; then
          autoUpdateAnswer=""
          echo $packages
          echo -n 'Package(s) above need to be updated, do you want to proceed? [y/n] : '
          read autoUpdateAnswer
          if [ $autoUpdateAnswer = 'y' ]
          then
            saved_dir=$(pwd)

            for package in $(cat $UPD_LOGFILE); do
              cd  $package

              # AUR build
              if [ -f 'PKGBUILD' ]; then
                git pull origin master
                makepkg -si
              else
                git pull
                git submodule update --init

                # project with CMakeLists.txt
                name=${PWD##*/}
                if [[ $name == 'source' && -f 'CMakeLists.txt' ]]
                then
                  # move to build directory
                  cd ../build

                  # build with ninja
                  if [ -f 'build.ninja' ]
                  then
                    ninja install
                  elif [ -f 'Makefile' ]
                  then
                    ncores=$(grep -c 'processor' /proc/cpuinfo)
                    make -j $ncores && make install
                  fi
                fi
              fi
            done

            # return to original directory
            cd $saved_dir
          elif [ $autoUpdateAnswer = 'n' ]
          then
            touch $UPD_LOCKFILE

            if [ $UPD_NOTIFICATIONS ]
            then
              notify-send -u low 'System' "packages auto-install delayed for $UPD_WAITINGTIME s."
            fi
            (sleep $UPD_WAITINGTIME && rm -f $UPD_LOCKFILE 2> /dev/null)&
          fi
        fi

        echo -n '' > $UPD_LOGFILE
      fi
    fi
  fi
