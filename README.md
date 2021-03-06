 
# passman.sh

Script that creates an encypted file to store usernames and passwords for services such as gmail, dropbox, etc. The file is alphabetized based on the name of the service followed by username and finally password.

# Installation

    git clone https://github.com/caodonnell/passman.sh

Requires `gpg`, which can be installed with `brew install gpg`.

Currently only for Mac OSX - uses `pbcopy` to copy passwords to the clipboard. For Linux, replace `pbcopy` with `xclip` (to send text to the clipboad with xlcip, use `xclip -selection clipboard`). If you're on Windows...figure it out yourself (sorry).

You'll also need to adjust the path to the password safe (line 10 of passman.sh). I have my password safe in my Dropbox.

# Use

Run the script interactively with `./passman.sh/passman.sh`.  Alternatively, create a symbolic link (e.g., `ln -s ~/passman.sh/passman.sh ~/passman `) to access the script. 

Type `r` to read a password(s) [note: `r` is the default behavior]. The script will ask if there's a relevant service or username. The default option is to read all passwords, and the output will be `{service} {username} {password}`. If you pick a particular service or username, the script will see if there are multiple matches. If there are, it will print all of the relevant service and username combinations. It will ask you if you wish to pick a specific entry (note: you only have to input enough so that the choice is unique). If you do not choose a particular username, it will use its default behavior, which is to print all of the relevant entries in the `{service} {username} {password}` format. If you do choose a specific entry, that password will be copied to the clipboard. If the choice of service is unique, the username will be printed to the screen and the password will be copied to the clipboard. 

Type `w` to write a password. The script will ask for the relevant service (gmail, netflix, dropbox, etc.), username, and password. It is currently possible to have mutliple username and password combinations linked to the same service (e.g., if you have 3 gmail accounts, they can all be listed as 'gmail', though I'd still suggest having unique names for each account (e.g., 'gmail-school', 'gmail-personal', etc.)

Type `d` to delete a password. The script will ask for the relevant service. If there are multiple username and password combinations associated with the service, it will ask you to pick the relevant username for deletion. If you mistype the username, it will throw an error.

Type `u` to update a password. The script will ask for the relevant service. If there are multiple usernames associated with that service, it will ask you to pick the relevant username. An incorrect username from a typo will cause the script to exit with an error. You will be asked if you want the script to generate a password or enter one of your own, and it will update the entry with the new password.

Options can also be passed on the command line. Here are some examples:

`./passman.sh w gmail mygmail@gmail.com 30` to create a password for 'gmail' with a length of 30 characters for the username 'mygmail [at] gmail [dot] com'. Append `<space>q` to suppress password output.

`./passman.sh w gmail mygmail@gmail.com mygmailpassword` to set 'mygmailpasword' as the password for 'gmail' with the username 'mygmail [at] gmail [dot] com'.

`./passman.sh r gmail` to read the password for 'gmail'.

`./passman.sh d gmail` to delete the password for 'gmail'.

`./passman.sh u gmail mygmail@gmail.com 30` to update the passowrd for 'mygmail [at] gmail [dot] com' with a new password with a length of 30 characters.

The script and `pwd.sh.safe` encrypted file can be safely shared between machines over public channels (Google Drive, Dropbox, etc).

A sample `gpg.conf` configuration file is provided for your consideration.


# pwd.sh

The original inspiration for passman.sh. It isn't necessary for passman.sh to work, but I've included it as a reference (in case something breaks in passman because bash scripting isn't my strong suit) as well as to give credit. Or in case I decide to just store passwords at some point. More information is in license.md and at [the pwd.sh github page](https://github.com/drduh/pwd.sh).
