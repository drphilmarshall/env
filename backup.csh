#! /bin/tcsh
# ======================================================================
#+
# NAME:
#   backup.csh
#
# PURPOSE:
#   Backup the relevant contents of home space to SLAC.
#
# COMMENTS:
#   Can expect something like 5Mb per second to UCSB.
#   Should be used as a cron job, with cron table something like:
#     ardua 0 4  * * 6   /home/pjm/cvs/env/backup.csh
#   Synchonization is in Export/Import order - be careful when using --delete!
#
# INPUTS:
#
# OPTIONAL INPUTS:
#   -r --reverse       Reverse the direction (ie import from the backup directory? [0]
#   -s --synchronize   Synchronize (ie first backup, then import)? [0]
#   -d --delete        Repeat deletion of files in other location? [0]
#   --remote-host      Name of remote host to backup to [pjm@ki-rh6.slac.stanford.edu]
#   --remote-dir       Name of remote directory to backup into [/nfs/slac/g/ki/ki09/pjm]
#   --local-dir        Name of local directory to backup from [$HOME]
#   --monitor dt       Repeat backup every dt seconds [0]
#   -m --mail address  Send email on completion [0]
#   -v --verbose       Verbose output? [0]
#   -h --help
#
# OUTPUTS:
#
# EXAMPLES:
#   backup.csh -v
#
#   backup.csh -v -r -m 20 b \
#      --local-dir /sdata907/nirc9/2007sep29 \
#      --remote-host pjm@tartufo.physics.ucsb.edu
#      --remote-dir /data1/homedirs/gavazzi/public_html/SL2S/NIRC2070928/data
#
# BUGS:
#
# REVISION HISTORY:
#   2006-09-21  started Marshall  (UCSB)
#-
# ======================================================================

# Default options:

set help = 0
set vb = 0
set forward = 1
set reverse = 0
set delete = 0
set dt = 0
set email = 0
set address = 0
# set rhost = 'pjm@ki-ls07.slac.stanford.edu'
# set rdir = '/nfs/slac/g/ki/ki19/pjm'
# set wdir = '/nfs/slac/g/ki/ki09/pjm'
set rhost = 'pjm@sdf.slac.stanford.edu'
set rdir = '/sdf/group/kipac/u/pjm/ki19/'
set wdir = '/sdf/group/kipac/u/pjm/ki09/'
set ldir = $HOME

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
   case -v:        #  Be verbose
      shift argv
      set vb = 1
      breaksw
   case --{verbose}:
      shift argv
      set vb = 1
      breaksw
   case -d:        #  Use delete option to cull missing files
      shift argv
      set delete = 1
      breaksw
   case --{delete}:
      shift argv
      set delete = 1
      breaksw
   case -m:         #  Send email when done
      shift argv
      set email = 1
      set address = $argv[1]
      shift argv
      breaksw
   case --{monitor}: #  Monitoring every dt secs
      shift argv
      set dt = $argv[1]
      shift argv
      breaksw
   case -{s}:
      shift argv
      set forward = 1
      set reverse = 1
      breaksw
   case --{synchronize}:
      shift argv
      set forward = 1
      set reverse = 1
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
   case --{remote-host}:
      shift argv
      set rhost = $argv[1]
      shift argv
      breaksw
   case --{remote-dir}:
      shift argv
      set rdir = $argv[1]
      shift argv
      breaksw
   case --{local-dir}:
      shift argv
      set ldir = $argv[1]
      shift argv
      breaksw
   case --{cwd}:
      shift argv
      set here = `echo "$cwd:h" | sed s_${ldir}_''_g`
      set ldir = $cwd:h
      set rdir = ${rdir}${here}
      set dirs = ( $dirs $cwd:t )
      breaksw
   case *:
      set dirs = ( $dirs $argv[1] )
      shift argv
      breaksw
   endsw
end

# Online help:

if ( $help ) then
  print_script_header.csh $0
  goto FINISH
endif

# List of directories to back up:

if ($#dirs == 0) then
  set dirs = (\
              work\
              personal\
              public_html\
              csh\
              outreach\
              perl\
              python\
              scriptutils\
              travel\
              )
  echo "Standard directory set selected for backup"
else
  echo "Custom directory set selected for backup:"
  foreach k ( `seq $#dirs` )
   set fail = `\ls $ldir/$dirs[$k] | & grep "No such" | wc -l`
   if ($fail) then
    echo "  $ldir/$dirs[$k] could not be found, skipping"
    set dirs[$k] = 0
   else
    echo "  $ldir/$dirs[$k]"
   endif
  end
endif

# ------------------------------------------------------------------------------
# Using rsync to synchronise between here and SLAC:
#  - by default do not use --delete - side effect is that you have to remove
#    files in both places or else both filesystems will continue to grow!
#  - use -u to only update older files
#  - import first, then export? Doesn't matter as -u checks times and keeps the
#    most recent version. If you want to merge changes in files use git

set command = "rsync -rptgoDzu"
set command = "$command --exclude-from=${HOME}/.rsync-exclude"
if ($delete) set command = "$command --delete"
if ($vb) then
  set command = "$command -v"
else
  set command = "$command -q"
endif

BEGIN:

# ------------------------------------------------------------------------------
# Standard operation - back up to remote host:

if ($forward) then

 foreach dir ( $dirs )

  if ($dir == 0) goto NEXTB

  if ($dir == public_html) then
      set remotedir = $wdir
  else
      set remotedir = $rdir
  endif

  echo "Backing up directory to \
  ${rhost}:${remotedir}/${dir}"

  echo "$command ${ldir}/${dir}/ ${rhost}:${remotedir}/${dir}/" \
        > /tmp/backup.csh

  source /tmp/backup.csh

NEXTB:
 end

endif

# ------------------------------------------------------------------------------
# Reverse operation - import files from remote host:

if ($reverse) then

 foreach dir ( $dirs )

  if ($dir == 0) goto NEXTR

  if ($dir == public_html) then
      set remotedir = $wdir
  else
      set remotedir = $rdir
  endif

  echo "Importing directory from \
  ${rhost}:${remotedir}/${dir}"

  echo "$command ${rhost}:${remotedir}/${dir}/ ${ldir}/${dir}/" \
        > /tmp/backup.csh

  source /tmp/backup.csh

NEXTR:
 end

endif

# ------------------------------------------------------------------------------
# If monitoring, sleep for dt then re-do the backup...

if ($dt > 0) then
  echo ""
  if ($vb) echo "...waiting $dt seconds..."
  echo ""
  sleep $dt
  goto BEGIN
endif

# ------------------------------------------------------------------------------
# Send email when done?

if ($email == 1) then

  set message = "/tmp/backup.email"
  \rm -f $message
  set date = `now`

  echo "\
\
Morning!\
\
The following directories were backed up to ${rhost} at ${date}:\
" >! $message

  foreach k ( `seq $#dirs` )
    echo "  $ldir/$dirs[$k]" >> $message
  end

  echo "\
Best wishes,\
\
  backup.csh\
" >> $message

  mail -s "backup.csh was successful!" "$address" < $message

  echo "Report email sent to $address"

endif

# ------------------------------------------------------------------------------

FINISH:

# ==============================================================================
