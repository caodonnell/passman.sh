
# passman.sh

Script that creates an encypted file to store usernames and passwords for services such as gmail, dropbox, etc.

# Installation

    git clone https://github.com/caodonnell/pwd.sh

Requires `gpg`, which can be installed with `brew install gpg`.

Currently only for Mac OSX - uses `pbcopy` to copy passwords to the clipboard. For Linux, replace `pbcopy` with `xclip` (to send text to the clipboad with xlcip, use `xclip -selection clipboard`). If you're on Windows...figure it out yourself.

# Use

Run the script interactively with `./pwd.sh/passman.sh`.  Alternatively, create a symbolic link (e.g., `ln -s ~/passman ~/pwd.sh/passman.sh`) to access the script. 

Type `w` to write a password. The script will ask for the relevant service (gmail, netflix, dropbox, etc.), username, and password. Currently, this manager only works with 1 username/password combination per service (e.g., you can't have 3 accounts linked with the service 'gmail'). To add multiple accounts, customize the service name (e.g., 'gmail-school', 'gmail-personal', etc.).

Type `r` to read a password(s). The script will ask for the relevant service. The username will be printed to the screen and the password will be copied to the clipboard.

Type `d` to delete a password. The script will ask for the relevant service.

Options can also be passed on the command line. Here are some examples:

`./passman.sh w gmail mygmail@gmail.com 30` to create a password for 'gmail' with a length of 30 characters for the username 'mygmail@gmail.com'. Append `<space>q` to suppress password output.

`./passman.sh r mygmail@gmail.com` to read the password for 'mygmail@gmail.com'.

`./pwd.sh d dropbox` to delete the password for 'dropbox'.

The script and `pwd.sh.safe` encrypted file can be safely shared between machines over public channels (Google Drive, Dropbox, etc).

A sample `gpg.conf` configuration file is provided for your consideration.


# pwd.sh

The original inspiration for passman.sh

Script to manage passwords in an encrypted file using gpg. See the details from https://github.com/drduh/pwd.sh
