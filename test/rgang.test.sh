#! /bin/sh
#   This file (rgang.test.sh) was created by Ron Rechenmacher <ron@fnal.gov> on
#   Jun 16, 2003. "TERMS AND CONDITIONS" governing this file are in the README
#   or COPYING file. If you do not have such a file, one can be obtained by
#   contacting Ron or Fermi Lab in Batavia IL, 60510, phone: 630-840-3000.
#   $RCSfile: rgang.test.sh,v $
rev='$Revision: 1.9 $'
#   $Date: 2005/01/22 19:40:05 $

# THIS SCRIPT TESTS rgang AND IT'S "err-file" FEATURE

set -u
if [ "${1-}" = -x ];then set -x;shift;fi

CMD='>/dev/null'
if [ $# -lt 2 -o $# -gt 3 ];then
    echo "usage: $0 <rgang_path> <nodespec> [cmd]"
    echo "examples: $0 ./rgang.1.92.py w{1-5}{01-24},w60{1-8},nqcd0{1-8}0{1-6}"
    echo "          $0 ./rgang.1.92.py qcd0{1-8}{01-10} \"cat /etc/services\""
    echo "default cmd=\"$CMD\""
    exit 1
fi

RGANG=$1
NODESPEC=$2
if [ "${3-}" ];then CMD=$3; echo "using CMD=\"$CMD\"";fi

# init "all" file
$RGANG --list "$NODESPEC" >all


cleanup()
{   if [ "${killthis-}" ];then
        echo "cleanup killing pid=$killthis"
        kill $killthis
    fi
    exit 1
}
trap cleanup 1 2 15

ofile=rgang.test.`date +%y-%m-%d.%H:%M.%S`.out
echo "$rev testing $RGANG with initial nodespec=$NODESPEC and CMD=\"$CMD\"" >$ofile
$RGANG --version >>$ofile
tail -f $ofile &
killthis=$!

x=0
while [ -s all ];do
    x=`expr $x + 1`
    echo "`date`   `wc -l all`   $x"
    # must use absolute path "$PWD/all" to avoid confusion with one if farmlet
    # dir --- I'll change in next version of rgang (to support ./farmlet for
    # *local* farmlet
    time $RGANG --err-file=errs -n0 ./all "$CMD" >rgang.cmd.out
    status=$?
    if [ $status != 0 ];then echo "non-zero exit status=$status"; fi
    if [ -s errs ];then
        echo "removing errs:"
        cat errs
        $RGANG --list --skip=errs ./all >all.new
        mv -f all.new all
    fi
    sleep 15
done >>$ofile 2>&1
