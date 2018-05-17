# zscripts

*zscripts* is a set of `zsh` scripts designed for Arch Linux users.

Depending on the script you want to use, you must install some dependencies too:
- *update.sh*:
    * cronie    [optional]
    * dunst     [optional]
    * libnotify [optinal]

- *screen.sh*:
    * screen
    * htop
    * nload
    * nvidia-smi

- *lock.sh*:
    * i3lock
    * imagemagick
    * scrot

# Content
---------

Several scripts are also provided to make your life happier:

## Update

This script manage packages update.
It will check for system updates and also for sources included in the file
`$UPD_SOURCE_FILE`. By default, this file is `$HOME/.config/autoUpdateList`.
This file should contain a list of directory to watch for updates, one per
line. You can also add tags using `#` to manage how update will be managed.
there is actually four tag supported:
* `#master` *optional*: this is the default behaviour, update this git repository to any new commit only if the current branch is *master*.
* `#aur` *optional*: for aur repository, the script will automatically detect them even without the tag.
* `#branch`: update the current branch of this git repository, even if not on master
* `#tag`: update the current git repository only to new tagged version

Here is an example of such file:


```
$HOME/.config/zscript
$HOME/.config/zsh#master
$HOME/Software/aur/package1
$HOME/Software/aur/package2#aur
$HOME/Software/work/my_project#branch
$HOME/Software/lib/lib_release#tag
```

Here, scripts in `.config` asould be on *master* and so can be updated
automatically (same with and without the tag). The AUR packages are also
watched for update (with and without the tag).
Then, *my_project/* can be updated no matter which branch is the current one and
the *lib_release/* will be updated only on new tagged version.

### Use

This script work in two steps, first it check for update without touching any folder.
This allows the check for update to run in the background, like in a cron tab.
Here is an example of a cron to check for updates every hour:

`0 * * * * $HOME/zscripts/update.sh --scan`

Notice the `--scan` argument which is sent to specify that you want to check for update.

Then, to process to the update, you need to source the `update.sh` file.

`source $HOME/zscripts/update.sh`

If you add this line in your `.zshrc`, your shell will propose to update (if
needed) whenever you open it.

## Screen

This script is designed to be sourced in the `.zshrc` configuration file like the following:

`source $HOME/zscripts/screen.sh`

It is able to detect and load pre-configured GNU `screen` sessions.

## Lock

This script lock the screen and use a blurred screenshot image as lockscreen image. An optional image
(e.g. a logo) can be added at the center.

# User configuration
--------------------

Each script can be customized through different variables, take a look at the beginning of each script
after the section *Configuration variables*. Feel free to modify these variables to suit your needs
in a user configuration file.

By default, the script will try to source the file `$HOME/.zscripts.conf` else it will use the content
of the environment variable `$ZSCRIPTS_CONFIG_FILE` to get the path of the file.

It is **strongly** recommended to use the default path `$HOME/.zscripts.conf` to store user variables
for consistency reasons. In fact, the access to an environment variable depends on where it has been
defined, e.g. by default, `cron` won't have access to a variable defined in `.zshrc`.

ToDo
----
- [x] [update] load user configuration file
- [x] [update] avoid redundant package updates

