#! /bin/tcsh
# ==============================================================================
#+
# NAME:
#   stow.csh
#
# PURPOSE:
#   Stow a directory in the data directory, and make a link to it instead.
# 
# COMMENTS:
#   The idea is to stow things away at SLAC, so that when the work directory
#   is backed up to a laptop, space is made on the laptop, cleanly.
#   Its a good idea to backup the laptop to SLAC first...
#
# INPUTS:
#
# OPTIONAL INPUTS:
#   -r --reverse       Reverse the direction (ie import from the stow directory? [0] 
#   -h --help    
#
# OUTPUTS:
#
# EXAMPLES:
#   stow.csh -v  simulations
#
#   stow.csh -v -r simulations  
#
# BUGS:
#
# REVISION HISTORY:
#   2013-10-25  started Marshall  (KIPAC)
#-
# ==============================================================================

# Default options:

set help = 0
set vb = 0
set forward = 1
set reverse = 0
set dirs = ()

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
   case -{r}:
      shift argv
      set forward = 0
      set reverse = 1
      breaksw
   case --{reverse}:
      shift argv
      set forward = 0
      set reverse = 1
      breaksw
   case *:         
      set dirs = ( $dirs $argv[1] )
      shift argv
      breaksw
   endsw
end

# Online help:

if ( $help || $#dirs == 0 ) then
  more `which $0`
  goto FINISH
endif
  
set CURRENT_DIR = $cwd

# ------------------------------------------------------------------------------

if ($forward) then

    # Loop over directories to stow away:

    if ($#dirs == 0) then
      echo "No directory selected for stowing"
      goto FINISH
    endif    

    foreach dir ( $dirs )

        # If dir does not exists in CWD, skip it.
        if (! -e $dir) then
            echo "  Directory $dir does not exist, skipping..."
            goto NEXT
        endif
        
        # If dir already exists in ~/data, skip it.
        set target = `echo "$CURRENT_DIR/$dir" | sed s/work/data/g`
        if (-e $target) then
            echo "  Target directory $target already exists, skipping..."
            goto NEXT
        endif
        
        # It doesn't, so stow it.
        mkdir -p $target
        mv $dir/* $dir/.* $target/ >& /dev/null
        rmdir $dir
        ln -s $target .
        
        echo "Stowed contents of $dir to $target. New link:"
        ls -ld $dir
        
        NEXT:

    end

# ------------------------------------------------------------------------------

else

    # Loop over directories to unstow:

    if ($#dirs == 0) then
      echo "No directory selected for unstowing"
      goto FINISH
    endif    

    foreach dir ( $dirs )

        # If dir already exists *as a directory* in the CWD, skip it.
        set not_a_link = `\ls -ld $dir | grep -v '\->' | wc -l`
        if ($not_a_link) then
             echo "  Target $dir already exists as a directory, skipping..."
             goto RNEXT
        endif     
        
        # If dir does not exist as a directory in the store, skip it.
        set target = `echo "$CURRENT_DIR/$dir" | sed s/work/data/g`
        if (! -e $target) then
             echo "  Target directory $target does not exist, skipping..."
             goto RNEXT
        endif
        
        # It should be cool, so unstow it.
        \rm $dir
        mkdir -p $dir
        mv $target/* $target/.* $dir/ >& /dev/null
        rmdir $target
        
        echo "Unstowed contents of $target to $dir. New directory:"
        du -sh $dir
        
        RNEXT:

    end

# ------------------------------------------------------------------------------

endif

FINISH:

# ==============================================================================

