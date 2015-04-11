#!/bin/tcsh
#===============================================================================
#+
# NAME:
#   env_make_links.csh
#
# PURPOSE:
#   Make sure the links in the home directory are set up right.
# 
# COMMENTS:
#
# INPUTS:
#
# OPTIONAL INPUTS:
#   -v --verbose        Verbose output [0]
#   -f --force          Force new links to be made
#
# OUTPUTS:
#
# EXAMPLES:
#   env_make_links.csh -v
#   
#
# BUGS:
#
# REVISION HISTORY:
#   2006-09-21  started Marshall  (UCSB)
#-
#===============================================================================

# Default options:

set help = 0
set vb = 0
set klobber = 0

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
   case -v:        #  Be verbose
      shift argv
      set vb = 1
      breaksw
   case --{verbose}:        
      shift argv
      set vb = 1
      breaksw
   case -f:        #  Force new links to be made
      shift argv
      set klobber = 1
      breaksw
   case --{force}:        
      shift argv
      set klobber = 1
      breaksw
   endsw
end

# Online help:

if ( $help ) then
  more $0
  goto FINISH
endif

# Make links!

set SRCDIR = $HOME/cvs/env/src


# First do .* files in home directory:

chdir $HOME

set sources = `\ls $SRCDIR | \
                 grep -v 'bookmarks.html' | \
                 grep -v 'prefs.js' | \
                 grep -v 'authorized_keys' | \
                 grep -v 'config'`

foreach source ( $sources )
  set remotefile = $SRCDIR/$source
  set target = .${source:t}
  echo "$target -> $remotefile"
  
  if ( -e $target && $klobber == 0 ) then
    if ($vb) echo "  $target exists, skipping"
  else
    \rm -f $target
    ln -s $remotefile $target
    if ($vb) echo "  Made soft link $target"
  endif  
end
      

# And finally do ssh keys and config:

set here = ${HOME}/.ssh
chdir $here
set remotefile = $SRCDIR/config
set target = ${remotefile:t}
echo "$target -> $remotefile"

if ( -e $target && $klobber == 0 ) then
  if ($vb) echo "  $target exists, skipping"
else
  \rm -f $target
  ln -s $remotefile $target
  if ($vb) echo "  Made soft link $target"
endif 

set here = ${HOME}/.ssh/.public
mkdir -p ${here}
chdir $here
set remotefile = $SRCDIR/authorized_keys
set target = ${remotefile:t}
echo "$target -> $remotefile"

if ( -e $target && $klobber == 0 ) then
  if ($vb) echo "  $target exists, skipping"
else
  \rm -f $target
  ln -s $remotefile $target
  if ($vb) echo "  Made soft link $target"
endif 

set here = ${HOME}/.ssh
chdir $here
\rm -f authorized_keys
ln -s .public/authorized_keys authorized_keys
\rm -f authorized_keys2
ln -s .public/authorized_keys authorized_keys2

FINISH:

#===============================================================================
