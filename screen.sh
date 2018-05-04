#!/usr/bin/zsh

## Configuration variables ##
# store the screen sessions in here
scr_sessionPath=$HOME/.screen/sessions

if [ -f $HOME/.zscripts.conf ]
then
  source $HOME/.zscripts.conf
elif [ -f $ZSCRIPTS_CONFIG_FILE ]
then
  source $ZSCRIPTS_CONFIG_FILE
fi

# detect if being sourced
if [[ $_ != $0 ]] && [[ $_ != $SHELL ]]
then
  # detect if gnu screen is used
  if [[ $TERM =~ 'screen' ]]
  then
    screenParsedFile=${STY#[0-9]*.}

    if [ -d $scr_sessionPath ]
    then
      screenSessionFile=$scr_sessionPath/$screenParsedFile
      if [ -f $screenSessionFile ]
      then
        if [ ! -f /tmp/$STY ]
        then
          screenLoadAnswer=""
          echo -n '['$screenParsedFile'] session file detected, do you want to load it? [y/n] : '
          read screenLoadAnswer
          if [ $screenLoadAnswer = "y" ]
          then
            clear
            screen -X source $screenSessionFile
            touch /tmp/$STY
          fi
        fi
      fi
    fi
  fi
fi
