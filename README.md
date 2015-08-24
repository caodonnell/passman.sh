 
# passman.sh

Script that creates an encypted file to store usernames and passwords for services such as gmail, dropbox, etc.

# Installation

    git clone https://github.com/caodonnell/pwd.sh

Requires `gpg`, which can be installed with `brew install gpg`.

Currently only for Mac OSX - uses `pbcopy` to copy passwords to the clipboard. For Linux, replace `pbcopy` with `xclip` (to send text to the clipboad with xlcip, use `xclip -selection clipboard`). If you're on Windows...figure it out yourself (sorry).

# Use

Run the script interactively with `./pwd.sh/passman.sh`.  Alternatively, create a symbolic link (e.g., `ln -s ~/pwd.sh/passman.sh ~/passman `) to access the script. 

Type `r` to read a password(s) [note: `r` is the default behavior]. The script will ask if there's a relevant service. The default option is to read all passwords, and the output will be `{service} {username} {password}`. If you pick a particular service, the username will be printed to the screen and the password will be copied to the clipboard. 

Type `w` to write a password. The script will ask for the relevant service (gmail, netflix, dropbox, etc.), username, and password. Currently, this manager only works with 1 username/password combination per service (e.g., you can't have 3 accounts linked with the service 'gmail'). To add multiple accounts, customize the service name (e.g., 'gmail-school', 'gmail-personal', etc.).

Type `d` to delete a password. The script will ask for the relevant service.

Options can also be passed on the command line. Here are some examples:

`./passman.sh w gmail mygmail@gmail.com 30` to create a password for 'gmail' with a length of 30 characters for the username 'mygmail [at] gmail [dot] com'. Append `<space>q` to suppress password output.

`./passman.sh r mygmail@gmail.com` to read the password for 'mygmail [at] gmail [dot]com'.

`./pwd.sh d dropbox` to delete the password for 'dropbox'.

The script and `pwd.sh.safe` encrypted file can be safely shared between machines over public channels (Google Drive, Dropbox, etc).

A sample `gpg.conf` configuration file is provided for your consideration.


# pwd.sh

The original inspiration for passman.sh. It isn't necessary for passman.sh to work, but I've included it as a reference (in case something breaks in passman because bash scripting isn't my strong suit) as well as to give credit. Or in case I decide to just store passwords at some point. More information is in license.md and at [the pwd.sh github page](https://github.com/drduh/pwd.sh).
