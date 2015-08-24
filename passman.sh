#!/usr/bin/env bash
#
# Script for managing passwords in a symmetrically encrypted file using GnuPG.

set -o errtrace
set -o nounset
set -o pipefail

gpg=$(command -v gpg || command -v gpg2)
safe=${PWDSH_SAFE:=~/pwd.sh/passman.sh.safe}


fail () {
  # Print an error message and exit.

  tput setaf 1 ; echo "Error: ${1}" ; tput sgr0
  exit 1
}


get_pass () {
  # Prompt for a password.

  password=''
  prompt="${1}"

  while IFS= read -p "${prompt}" -r -s -n 1 char ; do
    if [[ ${char} == $'\0' ]] ; then
      break
    elif [[ ${char} == $'\177' ]] ; then
      if [[ -z "${password}" ]] ; then
        prompt=""
      else
        prompt=$'\b \b'
        password="${password%?}"
      fi
    else
      prompt="*"
      password+="${char}"
    fi
  done

  if [[ -z ${password} ]] ; then
    fail "No password provided"
  fi
}


decrypt () {
  # Decrypt with a password.

  echo "${1}" | ${gpg} \
    --decrypt --armor --batch \
    --passphrase-fd 0 "${2}" 2>/dev/null
}


encrypt () {
  # Encrypt with a password.

  ${gpg} \
    --symmetric --armor --batch --yes \
    --passphrase-fd 3 \
    --output "${2}" "${3}" 3< <(echo "${1}")
}


read_pass () {
  # Read a password from safe.
  # Prints the username and copied the password to the clipboard

  if [[ ! -s ${safe} ]] ; then
    fail "No passwords found"
  fi

  if [[ -z "${2+x}" ]] ; then
    read -p "
  Service to read (default: all)? " service 
  else
    service="${2}"
  fi

  get_pass "
  Enter password to unlock safe: " ; printf "\n\n"

  if [[ -z ${service} || ${service} == "all" ]] ; then
    decrypt ${password} ${safe} || fail "Decryption failed"
  else
    info=$(decrypt ${password} ${safe} | grep -i "${service} ") \
                                || fail "Decryption failed"

    # Check for multiple entries or no entries
    # If all's good, then print username and copy the password
    nentries=$(echo $info | grep -oi "${service} " | wc -l)
    if [[  $nentries -ge 2 ]] ; then
      read -p "
  Username (default: print all usernames)? " uname
      if [[ -z ${uname} ]] ; then
        echo $info | grep -i "${service} " | while read -r line ; do
          awk '{print $2}'
        done
      else
        infonew=$(echo $info | grep -i "${service} ${uname}")
        echo $infonew | awk '{print $3}' \
                   | pbcopy \
                   | echo "(password copied to clipboard)"
      fi
    elif [[ $nentries -eq 0 ]] ; then
      fail "No entries for ${service}"
    else 
      echo $info | awk '{print $2}'
      echo $info | awk '{print $3}' \
                 | pbcopy \
                 | echo "(password copied to clipboard)"
    fi
 
  fi
}


gen_pass () {
  # Generate a password.

  len=50
  max=100
  
  if [[ -z "${4+x}" ]] ; then
    read -p "
  Password length? (default: ${len}, max: ${max}) " length
  else
    length="${4}"
  fi

  if [[ ${length} =~ ^[0-9]+$ ]] ; then
    len=${length}
  fi

  # base64: 4 characters for every 3 bytes
  ${gpg} --gen-random -a 0 "$((${max} * 3/4))" | cut -c -${len}
}


write_pass () {
  # Write a password in safe.

  # If no password provided, clear the entry by writing an empty line.
  if [ -z ${userpass+x} ] ; then
    new_entry=" "
  else
    new_entry="${service} ${username} ${userpass}"
  fi

  get_pass "
  Enter password to unlock safe: " ; echo

  # If safe exists, decrypt it and filter out service, or bail on error.
  # If successful, append new entry, or blank line.
  # Filter out any blank lines.
  # Finally, encrypt it all to a new safe file, or fail.
  # If successful, update to new safe file.
  ( if [ -f ${safe} ] ; then
      decrypt ${password} ${safe} | \
      grep -vi "${service} " || return
    fi ; \
    echo "${new_entry}") | \
    grep -ve "^[[:space:]]*$" | \
    encrypt ${password} ${safe}.new - || fail "Encryption failed"
    mv ${safe}.new ${safe}
}


create_username () {
  # Create a new username and password associated with a service.

  if [[ -z "${2+x}" ]] ; then
    read -p "
  Service: " service
  else
    service="${2}"
  fi

  if [[ -z "${3+x}" ]] ; then
    read -p "
  Username: " -r username
  else
    username="${3}"
  fi

  re='^[0-9]+$'

  if [[ -z "${4+x}" ]] ; then
    read -p "
  Generate password? (y/n, default: y) " rand_pass
  elif [[ "${4}" =~ $re ]] ; then
    rand_pass="num"
  else
    rand_pass="pass"
  fi


  if [[ "${rand_pass}" =~ ^([nN][oO]|[nN])$ ]]; then
    get_pass "
  Enter password: " ; echo
    userpass=$password

  elif [[ "${rand_pass}" = "pass" ]] ; then
    userpass="${4}"

  else
    userpass=$(gen_pass "$@")
    #if [[ -z "${4+x}" || ! "${4}" =~ ^([qQ])$ ]] ; then 
    echo "
  Password: ${userpass}"
    #fi
  fi
}


sanity_check () {
  # Make sure required programs are installed and can be executed.

  if [[ -z ${gpg} && ! -x ${gpg} ]] ; then
    fail "GnuPG is not available"
  fi
}


sanity_check

if [[ -z "${1+x}" ]] ; then
  read -p "Read, write, or delete password? (r/w/d, default: r) " action
  printf "\n"
else
  action="${1}"
fi

if [[ "${action}" =~ ^([wW])$ ]] ; then
  create_username "$@"
  write_pass

elif [[ "${action}" =~ ^([dD])$ ]] ; then
  if [[ -z "${2+x}" ]] ; then
    read -p "
  Service to delete? " service
  else
    service="${2}"
  fi
  write_pass

else 
  read_pass "$@"
fi

tput setaf 2 ; echo "
Done" ; tput sgr0
