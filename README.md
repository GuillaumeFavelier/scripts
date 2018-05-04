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

Scripts
-------
Several scripts are also provided to make your life happier:

- **update**

This script typically visits source directories to check for updates. It currently support `git` and `zsh`
and is able to check in particular Arch User Repositories (AUR) or other git versioned repositories and
system updates.

You can add this script to a cron table and if the correct dependencies are installed, notifications
will be sent. For example, to check for updates every hour:

`0 * * * * $HOME/zscripts/update.sh --scan`

Notice the `--scan` argument which is sent to specify that you want to check for update.

Optionally, an automatic installation procedure is applied as soon as updates are detected
if you source this script from your .zshrc file like the following:

`source $HOME/zscripts/update.sh`

- **screen**
- **lock**

User variables
--------------

Each script can be customized through different variables, take a look at the beginning of each script
after the section *Configuration variables*. Feel free to modify these variables to suit your needs
in a user configuration file.

By default, the script will try to source the file `$HOME/.zscripts.conf` else it will use the content
of the environment variable `$ZSCRIPTS_CONFIG_FILE` to get the path of the file.

It is **strongly** recommended to use the default path `$HOME/.zscripts.conf` to store user variables
for consistency reasons. In fact, the access to an environment variable depends on where it has been
defined, for example `cron` won't have access to a variable defined in `.zshrc`.

ToDo
----
- [x] basic scripts for auto-detection of updates with notifications
- [x] clean the scripts and add configuration variables
- [x] load user configuration file

