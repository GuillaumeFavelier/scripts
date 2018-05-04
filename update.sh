#!/usr/bin/zsh

## Configuration variables ##
# allow the script to send notifications
g_enableNotification='yes'

# duration of the lock in seconds
upd_waitingTime='300'

# path to the lock file, during locking
# no update installation will be done
upd_lockFile='/tmp/auto_update.lock'

# path to the update checking log
upd_logFile='/tmp/auto_update.log'

# path to the source directory to check
upd_sourcePath=$HOME'/source'

# path to the file containing a list of
# sources to exclude
#upd_excludeFile=$HOME'/.exclude'

if [ -f $HOME/.zscripts.conf ]
then
  source $HOME/.zscripts.conf
elif [ -f $ZSCRIPTS_CONFIG_FILE ]
then
  source $ZSCRIPTS_CONFIG_FILE
fi

if [[ $# -gt '0' ]] && [[ $1 = '--scan' ]]
then
  ## Start update detection system ##

  # make display available
  if [ $g_enableNotification = 'yes' ]
  then
    export DISPLAY=$(ps -u $(id -u) -o pid= | \
      while read pid; do
        cat /proc/$pid/environ 2>/dev/null | tr '\0' '\n' | grep '^DISPLAY=:'
      done | grep -o ':[0-9]*' | sort -u)

      notify-send -u low 'System' 'Checking source packages...'
    fi

    if [[ -z $upd_excludeFile && -f $upd_excludeFile ]]
    then
      for i in $(cat $upd_excludeFile)
      do
        args+=$(echo -n '-I' $i' ')
      done
    fi

    packageList=''

    # remove all fancy options on ls
    ls_cmd='\ls '$upd_sourcePath' '$args
    for i in $(eval $ls_cmd)
    do
      current=$upd_sourcePath/$i

      echo $current

      # move to the target directory
      cd $current

      if [ ! -d '.git' ]
      then
        if [ -d 'source' ]
        then
          current=$current'/source'
          cd $current
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
        echo $current >> $upd_logFile
      elif [ -f 'PKGBUILD' ]
      then
        pkgname=$(makepkg --printsrcinfo | grep 'pkgname =' | cut -f 2 -d =)

        # AUR: updated but check if installed
        ret=$(pacman -Q ${pkgname/ /})
        if [ $? -ne '0' ]
        then
          packageList+=$i' '
          echo $current >> $upd_logFile
        fi
      fi
    done

    toNotify=$(wc -l $upd_logFile | cut -f1 -d \  )
    if [[ $toNotify -gt '0' ]] && [[ $g_enableNotification = 'yes' ]]
    then
      notify-send -u normal 'System update' 'Custom Packages: '$packageList
    fi

    nbupdates=$(checkupdates | wc -l)
    if [[ $nbupdates -gt '0' ]] && [[ $g_enableNotification = 'yes' ]]
    then
      notify-send -u normal 'System update' 'Base packages: '$nbupdates
    fi
  else
    # detect if being sourced
    if [[ $_ != $0 ]] && [[ $_ != $SHELL ]]
    then
      ## Start auto-update system ##
      if [[ ! -f $upd_lockFile ]] && [[ -f $upd_logFile ]]
      then
        packages=$(cat $upd_logFile 2> /dev/null)
        numberOfUpdates=$(wc -l $upd_logFile 2> /dev/null | cut -f1 -d\ )
        if [ $numberOfUpdates -ge 1 ]; then
          autoUpdateAnswer=""
          echo $packages
          echo -n 'The packages above need to be updated, do you want to proceed? [y/n] : '
          read autoUpdateAnswer
          if [ $autoUpdateAnswer = 'y' ]
          then
            saved_dir=$(pwd)

            for package in $(cat $upd_logFile); do
              cd $package

              # AUR build
              if [ -f 'PKGBUILD' ]; then
                git pull origin master
                makepkg -si
              else
                git pull
                git submodule update --init

                # project with CMakeLists.txt
                name=${PWD##*/}
                if [[ $name == 'source' ]] && [[ -f 'CMakeLists.txt' ]]
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
            touch $upd_lockFile

            if [ $g_enableNotification = 'yes']
            then
              notify-send -u low 'System' "packages auto-install delayed for $upd_waitingTime s."
            fi
            (sleep $upd_waitingTime && rm -f $upd_lockFile 2> /dev/null)&
          fi
        fi

        echo -n '' > $upd_logFile
      fi
    fi
  fi
