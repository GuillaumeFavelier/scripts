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
if [ -z $UPD_WAITING_TIME ]
then
    UPD_WAITING_TIME='300'
fi

# path to the lock file, during locking
# no update installation will be done
if [ -z $UPD_LOCK_FILE ]
then
    UPD_LOCK_FILE='/tmp/auto_update.lock'
fi

# path to the update checking log
if [ -z $UPD_LOG_FILE ]
then
    UPD_LOG_FILE='/tmp/auto_update.log'
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

  ## Start update detection system ##
if [[ $# -gt '0' && $1 = '--scan' ]]
then
  # the script is going to scan for new
  # packages so we empty the log list
  cat /dev/null > $UPD_LOG_FILE

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
        if [ -d 'source' ]
        then
          source_dir=$source_dir'/source'
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
              echo $source_dir#$method >> $UPD_LOG_FILE
          fi
      elif [[ $method = "tag" ]]
      then
          lastTag=$(git describe --tags `git rev-list --tags --max-count=1`)
          curTag=$(git describe --tags)
          if [[ $lastTag != $curTag ]]
          then
              packageList+=$packageName' '
              echo $source_dir#$method >> $UPD_LOG_FILE
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
                  echo $source_dir#$method >> $UPD_LOG_FILE
              fi
          else
              echo "Error: No PKGBUILD file in an aur repository"
          fi
      fi
  done

    toNotify=$(wc -l $UPD_LOG_FILE | cut -f1 -d \  )
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
      if [[ ! -f $UPD_LOCK_FILE && -f $UPD_LOG_FILE ]]
      then
        packages=$(cat $UPD_LOG_FILE 2> /dev/null)
        numberOfUpdates=$(wc -l $UPD_LOG_FILE 2> /dev/null | cut -f1 -d\ )
        if [ $numberOfUpdates -ge 1 ]; then
          autoUpdateAnswer=""
          echo $packages
          echo -n 'Package(s) above need to be updated, do you want to proceed? [y/n] : '
          read autoUpdateAnswer
          if [ $autoUpdateAnswer = 'y' ]
          then
            saved_dir=$(pwd)

            for line in $(cat $UPD_LOG_FILE); do
              package=${line%\#*}
              method='master'
              if [[ ${line} = *"#"* ]]
              then
                method=${line#*\#}
              fi

              cd  $package

              # AUR build
              if [[ $method = "aur" || -f 'PKGBUILD' ]]; then
                git pull origin master
                makepkg -si
              else
                if [[ $method == "tag" ]]
                then
                    lastTag=$(git describe --tags `git rev-list --tags --max-count=1`)
                    git checkout $lastTag
                else
                    git pull
                fi
                git submodule update --init

                # project with CMakeLists.txt
                if [[ -f 'CMakeLists.txt' ]]
                then
                  if [[ -d 'build'  ]]
                  then
                      buildDir='./build'
                  elif [[ -d '../build' ]]
                  then
                      buildDir='../build'
                  else
                      echo "build dir not found"
                      continue
                  fi
                  # move to build directory
                  cd $buildDir

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
            touch $UPD_LOCK_FILE

            if [ $UPD_NOTIFICATIONS ]
            then
              notify-send -u low 'System' "packages auto-install delayed for $UPD_WAITING_TIME s."
            fi
            (sleep $UPD_WAITING_TIME && rm -f $UPD_LOCK_FILE 2> /dev/null)&
          fi
        fi

        echo -n '' > $UPD_LOG_FILE
      fi
    fi
  fi
