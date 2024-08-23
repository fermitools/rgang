#! /bin/sh
#   This file (killRestart.sh) was created by Ron Rechenmacher <ron@fnal.gov> on
#   Jan 22, 2005. "TERMS AND CONDITIONS" governing this file are in the README
#   or COPYING file. If you do not have such a file, one can be obtained by
#   contacting Ron or Fermi Lab in Batavia IL, 60510, phone: 630-840-3000.
#   $RCSfile: killRestart.sh,v $
#   $Revision: 1.1 $
#   $Date: 2005/02/11 03:02:29 $

#   from Markus' email:
#   - check if a specific executable is running on a list of nodes
#       - kill it
#       - restart it

set -u; if [ "${1-}" = -x ];then set -x; shift; fi

USAGE="\
  usage: $0 <node_list> <executable> [args]
example: $0 [options] b0evb{02-16} /home/ron/test.sh
This scripts sends a kill signal to all processes in the process group
associated with the specified executable.
With no option, the script will only kill and restart if the
executable is running.
Options:
  --start     start the executable even if it was not running
  --stop      just kill; do not restart
"

opts_wo_args='help|stop|start'
while op=`expr "${1-}" : '-\(.*\)'`;do
    opts="${opts-} -$op"; shift
    if xx=`expr "$op" : '-\(.*\)'`;then
        # double - (--) arg; could check for '='???
        op=$xx
    else
        op=`echo "$op" | perl -e '$_=<>;$_=~s/(.)/"$1" /g;print "$_"'`
    fi
    eval "for opt in $op;do
        case \$opt in
        \\?|h|help) echo \"\$USAGE\"; exit 0;;
        $opts_wo_args)
            eval opt_\`echo \$opt |sed -e 's/-/_/g'\`=1;;
        *)  echo \"invalid option: \$opt\";echo \"\$USAGE\"; exit 1;;
        esac
    done"
done

if [ ! "${2-}" ];then echo "$USAGE"; exit; fi

cleanup() { rm -f /tmp/rgang.$$; }
trap cleanup 1 2 15

nodelst="$1"
CMD=$2
CC=`basename $2`  # the -C option to ps just wants a basename
shift 2

rcmd="
#       ps --no-header --format pid,pgrp,comm,args -C 
plist=\`ps --no-header --format '%p %r %c %a' -C $CC\`
plist1=\`echo \"\$plist\" | head -1\`   # incase there is more than 1
cmd=\`echo \$plist1  | cut -d' ' -f4\`
#args=\`echo \$plist1 | cut -d' ' -f5-\`
if [ \"\`basename \\\"\$cmd\\\"\`\" != $CC ];then  # cmd might be ''
   cmd=\`echo \$plist1  | cut -d' ' -f5\`
   #args=\`echo \$plist1 | cut -d' ' -f6-\`
fi
if [ ! \"\$cmd\" ];then cmd=$CMD;fi
pids=\`echo \"\$plist\" |awk '{ print \$2 }'\` # get the process group id
#echo plist is \$plist
#echo cmd is \$cmd
#echo args is \$args
if [ \"\$pids\" ];then
    #echo kill -HUP -\`echo \$pids | sed 's/ / -/g'\`
    kill -HUP -\`echo \$pids | sed 's/ / -/g'\`
fi
if [ \( ! \"${opt_stop-}\" \) -o \"${opt_start-}\" ];then
    \$cmd $@ >/dev/null 2>&1 &
fi
"

# user can override by setting a different value for RGANG_RSH
if [ ! "${RGANG_RSH-}" ];then RGANG_RSH=ssh; fi
if hash rgang 2>/dev/null;then
    rgang -n --err-file=/tmp/rgang.$$ --do-local "$nodelst" "$rcmd"
    if [ -s /tmp/rgang.$$ ];then
        echo problems with:
        cat /tmp/rgang.$$
    fi
    cleanup
else
    echo "$0: critical component \"rgang\" not found; Did you forget to setup?"
fi
