#!/bin/tcsh
#===============================================================================
#+
# NAME:
#   env_make_keychain.csh
#
# PURPOSE:
#   Cut a set of ssh keys for this host, copy to env/src directory, 
#   and synchronize with other keychains. Idea is to run this script on all
#   machines, and then cvsup, env_make_links on all machines
# 
# COMMENTS:
#
# INPUTS:
#
# OPTIONAL INPUTS:
#   -p --passphrase  passphrase   Recommended for higher security!
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
   endsw
end

# Online help:

if ( $help ) then
  echo "Usage:\
        env_make_links.csh \
	      [-h --help] \
  goto FINISH
endif

# Make links!

set SRCDIR = $HOME/cvs/env/src
chdir $SRCDIR

# Generate new set of keys on this host:

set keychain = $SRCDIR/authorized_keys.${HOST}

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

echo "${0:t}: generated set of public keys for ${HOST}:"
echo " "
wc -l $keychain
echo " "
cat $keychain
echo " "

# Check in to cvs!

echo "${0:t}: checking into cvs:"
echo " "
cvs add $keychain:t
cvs ci -m "" $keychain:t

# Now cvs update to get other keychains:
echo " "
echo "${0:t}: updating other keychains:"
echo " "

set tmpfile = /tmp/env_make_keychains.tmp
cvs update >& $tmpfile

grep -e authorized_keys $tmpfile
echo " "

# Make new master keychain:

set masterchain = $SRCDIR/authorized_keys
cat $SRCDIR/authorized_keys.* >&! $masterchain

echo "${0:t}: made new master keychain:"
echo " "
wc -l $masterchain
echo " "

echo "${0:t}: checking into cvs:"
echo " "

cvs ci -m "" $masterchain:t

echo " "

FINISH:

#===============================================================================
