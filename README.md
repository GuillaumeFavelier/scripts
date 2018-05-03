This set of scripts is designed for linux Arch users.

Depending on the script you want to use, you must install some dependencies too:
- update
```
cronie
dunst
libnotify
```

- screen
```
screen
htop
nload
nvidia-smi
```

- lock
```
i3lock
imagemagick
scrot
```

- wallpaper
```
nitrogen
```

Scripts
-------
Several scripts are also provided to make your life happier:

- **update**

This script typically visits source directories to check for updates. It currently support `git` and `zsh`
and is able to check in particular Arch User Repositories (AUR) or other git versioned repositories and
system updates.

You can add this script to a cron table and if the correct dependencies are installed, notifications
will be sent. For example, to check for updates every hour:

`0 * * * * $HOME/scripts/update.sh --scan`

Notice the `--scan` argument which is sent to specify that you want to check for update.

Optionally, an automatic installation procedure is applied as soon as updates are detected
if you source this script from your .zshrc file like the following:

`source $HOME/scripts/update.sh`

- **screen**
- **lock**
- **wallpaper**

ToDo
----
- [x] basic scripts for auto-detection of updates with notifications
- [x] clean the scripts and add configuration variables
- [ ] load user configuration file

