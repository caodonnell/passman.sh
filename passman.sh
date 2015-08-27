#!/usr/bin/env bash
#
# Script for managing passwords in a symmetrically encrypted file using GnuPG.

set -o errtrace
set -o nounset
set -o pipefail

gpg=$(command -v gpg || command -v gpg2)
safe=${PWDSH_SAFE:=~/Dropbox/misc/passman.sh.safe.backup.08242015}


fail () {
  # Print an error message and exit.

  tput setaf 1 ; echo "Error: ${1}" ; tput sgr0
  exit 1
}

containsElement () {
  # Check if an array contains a specific string
  local e
  for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
  return 1
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
  Service or username to read (default: all): " service 
  else
    service="${2}"
  fi

  get_pass "
  Enter password to unlock safe: " ; printf "\n\n"

  if [[ -z ${service} || ${service} == "all" ]] ; then
    decrypt ${password} ${safe} || fail "Decryption failed"
  else
    info=($(decrypt ${password} ${safe} | grep -i "${service} ")) \
                                || fail "Decryption failed"  
    # Check for multiple matches
    # If multiple, print the services and usernames
    # Ask if it should print all passwords or 
    # if a specific username should be read.
    # If just one, print the username and copy the password to the clipboard
    if [[ ${#info[@]} -gt 3 ]] ; then
      echo "
  Matching usernames for ${service}"
      for (( i=0; i<((${#info[@]}/3)); i++ )) ; do
        # echo "  "${info[(($i*3))]} ${info[(($i*3+1))]}
        echo "  " ${info[(($i*3+1))]}
      done
      read -p "
  Which username to read (default: all): " -r uname ; printf "\n\n"
      if [[ -z ${uname} || ${uname} == "all" ]] ; then
        decrypt ${password} ${safe} | grep -i "${service} "
      else
        infonew=($(decrypt ${password} ${safe} | grep -i "${service} ${uname}"))
        printf ${info[2]} | pbcopy \
                          | echo "(password copied to clipboard)" 
      fi
    else 
      echo ${info[1]}
      printf ${info[2]} | pbcopy \
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
  Password length (default: ${len}, max: ${max}): " length
  else
    length="${4}"
  fi

  if [[ ${length} =~ ^[0-9]+$ ]] ; then
    len=${length}
  fi

  # base64: 4 characters for every 3 bytes
  ${gpg} --gen-random -a 0 "$((${max} * 3/4))" | cut -c -${len}
}


#write_pass () {
#  # Write a password in safe.
#
#  # If no password provided, clear the entry by writing an empty line.
#  if [ -z ${userpass+x} ] ; then
#    new_entry=" "
#  else
#    new_entry="${service} ${username} ${userpass}"
#  fi
#
#  get_pass "
#  Enter password to unlock safe: " ; echo
#
#  # If safe exists, decrypt it and filter out service, or bail on error.
#  # If successful, append new entry, or blank line.
#  # Filter out any blank lines.
#  # Finally, encrypt it all to a new safe file, or fail.
#  # If successful, update to new safe file.
#  ( if [ -f ${safe} ] ; then
#      decrypt ${password} ${safe} | \
#      grep -vi "${service} " || return
#    fi ; \
#    echo "${new_entry}") | \
#    grep -ve "^[[:space:]]*$" | \
#    encrypt ${password} ${safe}.new - || fail "Encryption failed"
#    mv ${safe}.new ${safe}
#}


write_pass () {
  # Write a password in the safe.

  new_entry="${service} ${username} ${userpass}"
  
  get_pass "
  Enter password to unlock safe: " ; echo

  # If safe exists, decrypt it.
  # If successful, append new entry.
  # Filter out any blank lines.
  # Finally, encrypt it all to a new safe file, or fail.
  # If successful, update to new safe file.
  ( if [ -f ${safe} ] ; then
      decrypt ${password} ${safe} || fail "Decyrption failed"
    fi ; \
    echo "${new_entry}") | \
    grep -ve "^[[:space:]]*$" | \
    sort --ignore-case | \
    encrypt ${password} ${safe}.new - || fail "Encryption failed"
    mv ${safe}.new ${safe}
}


delete_pass () {
  # Delete a password from the safe.

  get_pass "
  Enter password to unlock safe: " ; echo

  # Check for multiple matches to the service chosen
   info=($(decrypt ${password} ${safe} | grep -i "${service} ")) \
                                || fail "Decryption failed"

   if [[ ${#info[@]} -gt 3 ]] ; then
     echo "
  Matching usernames for ${service}: "
     for (( i=0; i<((${#info[@]}/3)); i++ )) ; do
       echo "  "${info[((i*3+1))]}
     done   
     read -p "
  Which username to delete: " -r username
    if containsElement "${username}" "${info[@]}" ; then
      strmatch="${service} ${username}"
    else
      fail "Username is not allowed"
    fi
   else
     strmatch="$service"
   fi

   (decrypt ${password} ${safe} | \
   grep -vi "${strmatch}") | \
   grep -ve "^[[:space:]]*$" | \
   sort --ignore-case | \
   encrypt ${password} ${safe}.new - || fail "Encryption failed"
   mv ${safe}.new ${safe}
}

update_pass () {
  # Update a password from the safe.

  get_pass "
  Enter password to unlock safe: " ; echo

  safepass="$password"

  # Check for multiple matches to the service chosen
  info=($(decrypt ${safepass} ${safe} | grep -i "${service} ")) \
                                || fail "Decryption failed"

  if [[ ${#info[@]} -gt 3 ]] ; then
    echo "
  Matching usernames for ${service}: "
    for (( i=0; i<((${#info[@]}/3)); i++ )) ; do
      echo "  "${info[((i*3+1))]}
    done   
    read -p "
  Which username to update: " -r username
    if containsElement "${username}" "${info[@]}" ; then
      strmatch="${service} ${username}"
    else
      fail "Username is not allowed"
    fi
  else
    if [[ -z "$username" ]] ;  then
      username="${info[1]}"
      service="${service} ${username}"
    fi
    strmatch="${service}"
  fi

  create_pass "$@"   

  new_entry="${service} ${userpass}"

  # If safe exists, decrypt it.
  # If successful, append new entry.
  # Filter out any blank lines.
  # Finally, encrypt it all to a new safe file, or fail.
  # If successful, update to new safe file.
  ( if [ -f ${safe} ] ; then
      decrypt ${safepass} ${safe} | grep -vi "${strmatch}" \
       || fail "Decyrption failed"
    fi ; \
    echo "${new_entry}") | \
   grep -ve "^[[:space:]]*$" | \
   sort --ignore-case | \
   encrypt ${safepass} ${safe}.new - || fail "Encryption failed"
   mv ${safe}.new ${safe}
}



create_username () {
  # Create a new username associated with a service.

  if [[ -z "${3+x}" ]] ; then
    read -p "
  Username: " -r username
  else
    username="${3}"
  fi
}


create_pass () {
  # Create a new password

  re='^[0-9]+$'

  if [[ -z "${4+x}" ]] ; then
    read -p "
  Generate password (y/n, default: y): " rand_pass
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
    if [[ -z "${5+x}" || ! "${5}" =~ ^([qQ])$ ]] ; then 
    echo "
  Password: ${userpass}"
    fi
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
  read -p "Read, write, delete, or update password (r/w/d/u, default: r): " action
  printf "\n"
else
  action="${1}"
fi

# Back up old password safe
cp ${safe} ${safe}.backup

if [[ "${action}" =~ ^([wW])$ ]] ; then
  if [[ -z "${2+x}" ]] ; then
    read -p "
  Service to delete: " service
  else
    service="${2}"
  fi
  create_username "$@"
  create_pass "$@"
  write_pass

elif [[ "${action}" =~ ^([dD])$ ]] ; then
  if [[ -z "${2+x}" ]] ; then
    read -p "
  Service to delete: " service
  else
    service="${2}"
  fi
  if [[ ! -z "${3+x}" ]] ; then
    service="${service} ${3}"
  fi
  delete_pass

elif [[ "${action}" =~ ^([uU])$ ]] ; then
  if [[ -z "${2+x}" ]] ; then
    read -p "
  Service to update: " service
  else
    service="${2}"
  fi
  if [[ ! -z "${3+x}" ]] ; then
    username="${3}"
    service="${service} ${username}"
    # echo $service
  fi
  update_pass "$@"

else 
  read_pass "$@"
fi

tput setaf 2 ; echo "
Done" ; tput sgr0
