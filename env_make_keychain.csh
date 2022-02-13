#!/bin/tcsh
#===============================================================================
#+
# NAME:
#   env_make_keychain.csh
#
# PURPOSE:
#   Cut a set of ssh keys for this host, copy to env/src directory,
#   and synchronize with other keychains. Idea is to run this script on all
#   machines, and then git merge, env_make_links on all machines
#
# COMMENTS:
#
# INPUTS:
#
# OPTIONAL INPUTS:
#   -p --passphrase  passphrase   Recommended for higher security! [empty]
#   -n --new                      Make a new ssh key [don't]
#
# OUTPUTS:
#
# EXAMPLES:
#   env_make_keychain.csh
#
# BUGS:
#   - incomplete header documentation
#
# REVISION HISTORY:
#   2008-08-20  started Marshall  (UCSB)
#-
#===============================================================================

# Default options:

set help = 0
set vb = 0
set passphrase = ""
set new = 0

while ( $#argv > 0 )
   switch ($argv[1])
   case -h:        #  Print help
      shift argv
      set help = 1
      breaksw
   case --{help}:
      shift argv
      set help = 1
      breaksw
   case -p:        #  Provide passphrase
      shift argv
      set passphrase = "$argv[1]"
      shift argv
      breaksw
   case --{passphrase}:
      shift argv
      set passphrase = "$argv[1]"
      shift argv
      breaksw
   case -n:        #  Make new ssh key
      shift argv
      set new = 1
      breaksw
   case --{new}:
      shift argv
      set new = 1
      breaksw
   endsw
end

# Online help:

if ( $help ) then
    more `which $0`
    goto FINISH
endif

# Make links!

set SRCDIR = $HOME/env/src
chdir $SRCDIR

set keychain = $SRCDIR/authorized_keys.${HOST}

if ($new) then

    # Generate new set of keys on this host:

    # rsa:
    yes | ssh-keygen -t rsa -N "$passphrase" -f ${HOME}/.ssh/id_rsa >& /dev/null
    # rsa1:
    yes | ssh-keygen -t rsa1 -N "$passphrase" -f ${HOME}/.ssh/identity >& /dev/null
    # dsa:
    yes | ssh-keygen -t dsa -N "$passphrase" -f ${HOME}/.ssh/id_dsa >& /dev/null

    # Concatenate into authorized keys file:

    cat ${HOME}/.ssh/id_rsa.pub \
        ${HOME}/.ssh/identity.pub \
        ${HOME}/.ssh/id_dsa.pub      > $keychain

endif

echo "${0:t}: public keys for ${HOST}:"
echo " "

wc -l $keychain
echo " "
cat $keychain
echo " "

echo "${0:t}: checking ssh keys into repository:"
echo " "
git add $keychain:t
git commit -m "ssh keys on $HOST" $keychain:t
git push


# Now git pull to get other keychains:

echo " "
echo "${0:t}: updating other keychains:"
echo " "

set tmpfile = /tmp/env_make_keychains.tmp
git pull >& $tmpfile

grep -e authorized_keys $tmpfile
echo " "

# Make new master keychain:

set masterchain = $SRCDIR/authorized_keys
cat $SRCDIR/authorized_keys.* >&! $masterchain

echo "${0:t}: made new master keychain:"
echo " "
wc -l $masterchain
echo " "

echo "${0:t}: checking into repository:"
echo " "

git commit -m "Updating keychain from $HOST" $masterchain:t
git push

echo " "

FINISH:

#===============================================================================
