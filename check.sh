##!/bin/bash
#
# Check non-regression of all NRG cases containing nrgconf.sh
#
bar=$(printf "%79s" | tr ' ' =)

# --- print usage ---
#
function usage() {
  if [ $1 = 1 ] ; then
    echo "$bar"
    echo "ERROR"
    echo "$bar"
  fi
  echo
  echo "Usage: $SCRIPTNAME [-h] [-d|--diff-cmd <diff-command>]"
  echo "       $SCRIPTSPCE [-l] [--] [<pattern> ...]"
  echo
  echo "       -h:      prints this help"
#  echo "       -exe:   typhon executable (default is given by NRG conf)"
  echo "       -d|--diff-cmd <diff-command>:"
  echo "                uses <diff-command>"
  echo "       -l:      prints list of cases"
  echo "       -k:      keep (do not delete) TMPDIR and cases"
  echo "       --:      end of options"
  echo
  echo "       <pattern>: selects cases with name matching <pattern>"
  echo
  echo "       default: runs cases"
  echo
  exit $1
}

echo "$bar"
echo "TYPHON non regression check"
echo "$bar"

# --- directory initialization ---
#
ORIGDIR=$PWD
SCRIPTNAME=$(basename $0)
SCRIPTSPCE=$(sed 's/./ /g' <<< $SCRIPTNAME)
export HOMEDIR=$(cd $(dirname $0) ; pwd)
export  EXEDIR=$HOMEDIR/SOURCE
export  BINDIR=$HOMEDIR/bin
export  NRGDIR=$HOMEDIR/NRG
export MESHDIR=$HOMEDIR/NRG/COMMON
export  TMPDIR=$(mktemp -d /tmp/typhon.${SCRIPTNAME%.sh}.XXXXXXXX)
if [ $? -ne 0 ] ; then
  echo "could not create temporary directory"
  exit 1
fi

# --- directory check ---
#
if [ ! -d $MESHDIR ] ; then
  echo "directory $MESHDIR not found"
  echo "$HOMEDIR/$SCRIPTNAME is not in a valid typhon directory"
  exit 1
fi

# --- get options ---
#
#OPTS=$(getopt -o hd:lk -l diff-cmd: -n "$SCRIPTNAME" -- "$@")
#[[ $? != 0 ]] && usage 1
#eval set -- "$OPTS"

# --- parse options ---
#
typhonexe=
diffcmd=
list=0
keeptmpdir=0
patlist=()
while [ ${#} -gt 0 ] ; do
  case "$1" in
    -h) usage 0 ;;
    -d|--diff-cmd) shift
        if [ $# -gt 0 ] ; then
          diffcmd=$1
        else
          echo "ERROR: no diff command:"
          usage 1
        fi ;;
    -l) list=1 ;;
    -k) keeptmpdir=1 ;;
#    -exe) shift
#        if [ $# -gt 0 ] ; then
#          typhonexe=$1
#          echo force run with $typhonexe
#        else
#          echo "ERROR: no typhon command:"
#          usage 1
#        fi ;;
    --) shift ; break ;;
    *)  break ;;
  esac
  shift
done

# --- check patterns ---
#
if [ ${#} -gt 0 ] ; then
  for pat in "$@" ; do
    if [ -n "$pat" ] ; then
      patlist+=("-e" "$pat")
    fi
  done
  shift ${#}
fi

# --- initialization ---
#
cd $HOMEDIR
. bin/shconf.sh
if [ -n "$diffcmd" ] ; then
  {          cat $0 ;} | $diffcmd - $0 >/dev/null 2>&1 ; r=$?
  { echo a ; cat $0 ;} | $diffcmd - $0 >/dev/null 2>&1 ; r=$?$r
  if [ $r != 10 ] ; then
    echo "ERROR: check diff command:"
    echo "$diffcmd"
    usage 1
  fi
  export DIFF="$diffcmd"
fi
#
export REFCONF=nrgconf.sh
export DIFFCOM=$DIFF
export LD_LIBRARY_PATH=$EXEDIR/Lib:$LD_LIBRARY_PATH

if [ $keeptmpdir -eq 0 ] ; then
  trap "rm -Rf $TMPDIR" 0 2
fi

ok=1
for f in diff.log check.log ; do
  if [ -e $f ] && [ ! -f $f ] ; then
    echo "$f is not a regular file" ; ok=0
  fi
done
test $ok = 0 && exit 1
  
rm -f diff.log check.log

# --- get list of cases ---
#
cd $NRGDIR
LISTCASES=( $(find * -name $REFCONF | xargs -n 1 dirname | grep "${patlist[@]:-.}") )

if [ ${#LISTCASES[@]} = 0 ] ; then
  echo "NO CASE FOUND"
  echo "$bar"
  exit 0
fi

# --- print list of cases ---
#
if [ $list -eq 1 ] ; then
  echo LISTCASES =
  for CASE in "${LISTCASES[@]}" ; do
    echo "    ${CASE}"
  done
  exit 0
fi

# --- print parameter ---
#
scol0=
for CASE in "${LISTCASES[@]}" ; do
  scol0=$(printf "%${#scol0}s" "${CASE//?/ }")
done
scol1=$scol0$(printf "%15s")
ncol2=24

# --- tests ---
#
echo diffing with DIFF : $DIFF
echo "$bar"

function iferror() {
  test $? -ne 0
}

function next_case() {
  test $# -gt 0 && printf "$remain%s\n" "$@"
  test $keeptmpdir -eq 0 && rm -f $TMPDIR/$CASE/*
  continue
}

function next_fic() {
  test $# -gt 0 && printf "$remain%-${ncol2}s %s\n" "$@"
  continue
}

echo diff-command : $DIFFCOM >> $HOMEDIR/diff.log
for CASE in "${LISTCASES[@]}" ; do
  # init
  CASEDIR=$NRGDIR/$CASE
  # print
  string="checking $CASE ..."
  printf "$string" ; repl=${string//?/?} ; remain=${scol1/$repl/}
  # configure
  . $CASEDIR/$REFCONF
  iferror && next_case "source NRG/$CASE/$REFCONF: command failed"
  # create dir
  mkdir -p $TMPDIR/$CASE
  iferror && next_case "mkdir -p $TMPDIR/$CASE: command failed"
  cd $TMPDIR/$CASE
  # copy files
  cp $MESHDIR/$MESHFILE $TMPDIR/$CASE
  cp $CASEDIR/$INPUTFILE $TMPDIR/$CASE
  # create hostfile
  hostname > hostfile
  # write headers
  echo "$bar"  >> $HOMEDIR/check.log
  echo "$CASE" >> $HOMEDIR/check.log
  echo '#' "$bar"  >> $HOMEDIR/diff.log
  echo '#' "$CASE" >> $HOMEDIR/diff.log
  # check executable type
  case $TYPE_EXE in
    seq) exehead="" ;;
    mpi) exehead="mpirun -np ${MPIPROCS:-2} -machinefile hostfile" ;;
    *)   next_case "\"$TYPE_EXE\": unknown typhon executable type" ;;
  esac
  # check executable
  #if [ -n "$typhonexe" ] ; then
  #  EXE=$typhonexe
  #else
    EXE=$EXEDIR/Typhon-$TYPE_EXE
  #fi  
  test -f $EXE || next_case "\"$EXE\": no such file"
  test -x $EXE || next_case "\"$EXE\": execute permission denied"
  # execute
  echo run: $exehead $EXE >> $HOMEDIR/check.log
  $exehead $EXE >> $HOMEDIR/check.log 2>&1
  iferror && next_case "??   computation failed"
  for fic in $TO_CHECK ; do
    test -f "$fic" || next_fic "\"$fic\": file missing"
    fics=( $fic $CASEDIR/$fic )
    $DIFFCOM ${fics[@]} >> diff.log 2>&1
    case $? in
      0) diff ${fics[@]} >/dev/null 2>&1
         case $? in
           0) printf "$remain%-${ncol2}s %s\n" "$fic" "identical" ;;
           *) printf "$remain%-${ncol2}s %s\n" "$fic" "equal" ;;
         esac ;;
      1) printf "$remain%-${ncol2}s %s\n" "$fic" "changed"
         echo diff ${fics[@]} >> $HOMEDIR/diff.log
         cat diff.log >> $HOMEDIR/diff.log ;;
      *) printf "$remain%-${ncol2}s %s\n" "$fic" "comparison failed" ;;
    esac
    rm -f diff.log
    remain=$scol1
  done
  next_case
done
echo "$bar"

if [ $HOMEDIR = $ORIGDIR ] ; then
  echo check.log diff.log
else
  echo $HOMEDIR/check.log
  echo $HOMEDIR/diff.log
fi
echo "$bar"

if [ $keeptmpdir -eq 1 ] ; then
  echo "files kept in   : $TMPDIR"
  echo "$bar"
fi
