#!/bin/sh
# =============================================================================
# Script:	install.sh
# By:		SMK
# Date:		04/07/05
# Purpose:	installer for chkbk program
#
# License:      GPL
# License file  LICENSE.txt
# Email:        freesol29@gmail.com
#
# Copyright (C) 2005 Stephen M. Kaiser
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version
# 2 of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
# =============================================================================
CHKBK=""$HOME"/.chkbk"		# default home for chkbk
CHKBK_ALTHOME=""$HOME"/chkbk/"	# alt home for chkbk
CHKBK_ALTVARS="chkbk_altvars"	# file with alt vars 
BIN="chkbk"			# chkbk main exe file
BINDIR="$HOME"/bin""		# user installed dir for chkbk exe
CHKBK_ROOT=".chkbk"  		# chkbk dir if user is root
CHKBK_ROOT_BIN="/usr/local/bin" # where chkbk exe is stored if user is root
LOG=""$HOME"/.chkbk/install.log"	# chbkk's install log location
LOG_ALT=""$CHKBK_ALTHOME"/install.log" 	# chkbk's alternate log location
LOG_ROOT=/root/chkbk.install.log	# chkbk's log when installed as root
ROOT_UID=0 			# check root $UID
E_NOTROOT=67 			# Non-root exit code
E_NOPROCEED=68  		# decline install as root error code
CHKBK_EXISTS=69 		# code if $HOME/.chkbk exists 
E_QUIT=70			# exit code if user chooses to quit installer
TMP=/tmp/tmpf   		# make a temp file for doing some work
VERSION="1.55"   		# ChkBk version number


# check to see if we are root
isroot()
{
  if test `id -u` != "$ROOT_UID"
    then
      norootprompt
    else
      showproceed
  fi
}



# Ask the user if he/she wants to exit and become root or install
# as the uer
norootprompt()
{
rloop="y"
  while test "$rloop" = "y"
    do
      echo "Do you wanna become root (root) and install or try to install"
      echo -n "just for yourself (self)? (root/self) "
      read root

      case "$root" in
	root) norootmessage ; break ;;
	self) chgpath ; break ;;
	*) errpressenter ;;
      esac

    done
}



# Display a meesage to the user about what to do to restart the installation
# if he/she wasn't root
norootmessage()
{
  echo
  echo "To start installlation again become the root user"
  echo "by entering su - at the command prompt and enter root's"
  echo "password.  If you do not know root's password, you need"
  echo "to start the installation again and choose to install as self"

  pressenter
  install_exit

  exit $E_NOTROOT
}



## assume the user has root privs since they are using windoze
assumeroot()
{
admin_loop=y
admin=y
  echo ; echo
  echo "You are using CYGWIN...I will assume that you have"
  echo 'administrator privileges.  If you do not, type an "n"'
  echo "at the prompt to perform the install as a normal user"
  echo 'or type a "q" to quit the installer' 
  echo "altogether so you can become administrator."
    
    # continue to prompt the user to continue until he/she
    # displays the ability to follow instructions
    # default answer is set to yes, so we caontinue
    # with "root" install if user just presses enter.
  while test "$admin_loop" = "y"
  do
    echo
    echo -n "Continue (y/n)? [y] "
    read admin
    
      # test user input
    if test "$admin" = "n"
      then
        admin_loop=n ; echo ; echo ; chgpath
    elif test "$admin" = "q"
      then
        admin_loop=n ; install_exit ; exit $E_QUIT 
    elif test "$admin" = "y"
      then
        admin_loop=n ; echo ; echo ; showproceed
    elif test "$admin" = ""
      then
        admin_loop=n ; echo ; echo ; showproceed
    else
	  echo ; errpressenter
    fi
  done
}



chgpath()
{
ploop="y"
  while test "$ploop" = "y"
    do
      echo ; echo
      echo "Do you want to install ChkBK to "$HOME"/bin (bin)"
      echo "and update your \$PATH variable" 
      echo "        or"
      echo "install to "$CHKBK_ALTHOME" (alt)?"
      echo
      echo "The bin method should be safe, but the alt method is safer..."
      echo "choose alt if you are scared."
      echo ; echo
      echo "NOTE: IF YOU ARE USING WINDOWS, CHOOSE "alt"".
      echo "THERE ARE PROBLEMS WITH THE NEW PATH ACTUALLY BEING READ BY THE SHELL."
      echo ; echo
      echo -n "Please choose (bin/alt) "
      read installu

      if [ "$installu" = "bin" ]
        then
      	  mkchkbkdir ; break
  	elif [ "$installu" = "alt" ]
    	  then
      	    mkalthome ; break
  	else
          errpressenter
      fi
    done
}



# make .chkbk directory in the installing user's home dir
mkchkbkdir()
{
  # set variable to control loop
exists_loop=y
  if [ -d "$CHKBK" ]
    then
      echo ; echo
      echo "WARNING!!"
      echo
      echo ""$CHKBK" already exists"
      echo "Choosing "yes" here will delete the entire "$CHKBK" directory,"
      echo "including any existing databases."
      echo "If you just want to install, but keep your databases, say "no.""
        # give the user a chance to f*ck up and try again
      while [ "$exists_loop" = "y" ]
        do
          echo
          echo -n "Overwrite (yes/no)? "
          read owrite
          if [ "$owrite" = "yes" ]
            then
	      exists_loop=n ; removefiles ; installfiles
  	  elif [ "$owrite" = "no" ]
     	    then
	      exists_loop=n ; installfiles
	  else
	      errpressenter
          fi
      done	
  else
      installfiles
  fi
}



# removes existing chkbk directory
removefiles()
{
  echo "Removing "$CHKBK" and all its files..."
  rm -rvf "$CHKBK"
  sleep 1
}



# install chkbk files to $HOME/.chkbk
installfiles()
{
  echo ; echo
  echo "Installing files..."
  echo ; echo

  mkdir -p "$CHKBK" 2> /dev/null
  mkdir -p "$BINDIR" 2> /dev/null
  cp -fv changelog HELP.txt install.sh LICENSE.txt "$CHKBK" > "$LOG"
  cp -fv "$BIN" "$BINDIR" >> "$LOG"
  sleep 1
  echo "Done!"
  sleep 1
  updateprofile
  pressenter
  showhelp
}



# append new path to $PATH variable in .bash_profile
updateprofile()
{
nopath="$(echo $PATH | grep "$HOME/bin")"
  if [ -z "$nopath" ]
    then
      cp "$HOME"/.bash_profile "$HOME"/.bash_profile.chkbk
      echo "PATH=$PATH:$HOME/bin" >> "$HOME"/.bash_profile
      echo "export PATH" >> "$HOME"/.bash_profile
      echo ; echo ; echo
      echo "Your \$PATH has been updated, but you need to logout"
      echo "and log back in for the new path to take effect"
  fi
}



# make the alternate home location of chkbk dir
mkalthome()
{
  mkdir -p "$CHKBK_ALTHOME"
  cpfileshere
}



# make chkbk dir in intalling user's home directory if
# he/she chooses not to edit $PATH variable
cpfileshere()
{
  echo ; echo
  echo "Installing files..."
  echo ; echo

  cp -f changelog HELP.txt install.sh LICENSE.txt "$CHKBK_ALTHOME" > "$LOG_ALT"
  cp -f "$CHKBK_ALTVARS" "$HOME/chkbk/chkbk" >> "$LOG_ALT"
  pressenter
  showhelp
}



# Get home directories for all users(hopefully) on the system
# for install .chkbk dir to
gethomes()
{
  echo
  echo "Getting homes..."
  homes="$(ls /home | grep -v "lost+found" > "$TMP")"
  sleep 1
  echo
  echo "Found these homes:"
  cat "$TMP"

  makehomes
}



# make .chkbk dir in all users (hopefully) home dirs
makehomes()
{
  # remove any previous install.log
rm -f "$LOG_ROOT"
  echo
  echo "Copying files..."
  for home in `cat $TMP`
    do
      next_home=/home/"$home"/"$CHKBK_ROOT"
        # make /root directory to store install log if we are using cygwin
      if test "`uname -a | grep -i cygwin`" != ""
        then
  	  mkdir -p /root 2> /dev/null
      fi
	
      mkdir "$next_home" 2> /dev/null
      cp -fv changelog HELP.txt install.sh LICENSE.txt "$next_home" >> "$LOG_ROOT"
      chown -R "$home":"$home" "$next_home" 2> /dev/null 
    done
   
      # copy main program to public path
    cp -fv "$BIN" "$CHKBK_ROOT_BIN" >> "$LOG_ROOT"
    chmod 755 "$CHKBK_ROOT_BIN"/"$BIN"
    # pause for effect
  sleep 1
  echo
  echo "Done!"
  sleep 1
  pressenter
  showhelp
}



# Display a warning about installing as root and ask for confirmation to proceed
showproceed()
{
  echo
  echo -n "You are installing ChkBk as root.  This will attempt to make a .chkbk
	directory in each user's home directory that is listed in /home. 
	It will also install the main ChkBk program into "$CHKBK_ROOT_BIN".
	
	Do you wish to proceed (y/n)? [n] "
  read proceed
  if [ "$proceed" = "y" ]
    then 
      installu=bin ; gethomes
    else
      echo
      echo "As you wish My Lord!"
      install_exit
      exit $E_NOPROCEED
  fi
}



# Print message saying install is exiting and pause three seconds for effect :)
install_exit()
{
  echo
  echo "Install exiting...bye!"
  sleep 2 
}



# Display a brief help message after installation
showhelp()
{
  echo ; echo
  echo "The recommended terminal size settings to use ChkBk are at least 115x40.
 	The program should look fine at the usual default settings of 80x24
	but will look ugly when you try to check your balance."
    # test to see what type of install we did and give proper instructions
  if test "$installu" = "bin"
    then
      echo
      echo "To run Chkbk, open a terminal and type '""$BIN""' with no quotes at
	the prompt."
    else
      echo
      echo "To run Chkbk, open a terminal and type '"cd "$HOME"/chkbk"' with no 
	quotes then '"./"$BIN""' at the prompt."
  fi

  echo ; echo ; echo
  echo "Thanks for using ChkBk...Enjoy!"
  echo ; echo
}
		


showhelpalt()
{
  echo ; echo
  echo "The recommended terminal size settings to use ChkBk are at least 115x40.
 	The program should look fine at the usual default settings of 80x24
	but will look ugly when you try to check your balance.

	To run Chkbk, open a terminal and type '"cd "$HOME"/chkbk"' with no 
	quotes then '"./"$BIN""' at the prompt.

  Thanks for using ChkBk...Enjoy!\n\n\n"
}




# Prompt to continue
pressenter()
{
  echo
  echo "Press <ENTER> to continue" ; read prompt
}



# Display error message if invalid input was given
errpressenter()
{
  echo "Invalid input...Press <ENTER> to continue" ; read prompt
}



# Display usage message if commend line arguments were given
usage()
{
  echo "USAGE: Just run ./intall.sh with no arguments"
  echo
}



# Display copyright and license info as script starts
showlicense()
{
  echo "ChkBk "$VERSION" by Stephen Kaiser
  (C) Copyright 2005 see LICENSE.txt"
  echo ; echo
}
######################## Begin Program ##########################
if [ "$1" != "" ]
then
  usage         
  exit 127
elif test "`uname -a | grep -i cygwin`" != ""
  then
	showlicense ; assumeroot
else
  showlicense ; isroot
fi
			
