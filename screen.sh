#!/usr/bin/zsh

## Configuration variables ##
# store the screen sessions in here
if [ -z $SCR_SESSION_PATH ]
then
  SCR_SESSION_PATH=$HOME/.screen/sessions
fi

if [ -f $HOME/.zscripts.conf ]
then
  source $HOME/.zscripts.conf
elif [[ ! -z $ZSCRIPTS_CONFIG_FILE && -f $ZSCRIPTS_CONFIG_FILE ]]
then
  source $ZSCRIPTS_CONFIG_FILE
fi

# detect if being sourced
if [[ $_ != $0 && $_ != $SHELL ]]
then
  # detect if gnu screen is used
  if [[ $TERM =~ 'screen' ]]
  then
    screenParsedFile=${STY#[0-9]*.}

    if [ -d $SCR_SESSION_PATH ]
    then
      screenSessionFile=$SCR_SESSION_PATH/$screenParsedFile
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
