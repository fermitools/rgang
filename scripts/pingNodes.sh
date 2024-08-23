#! /bin/sh
#  This file (pingNodes.sh) was created by Ron Rechenmacher <ron@fnal.gov> on
#  Jan 20, 2005. "TERMS AND CONDITIONS" governing this file are in the README
#  or COPYING file. If you do not have such a file, one can be obtained by
#  contacting Ron or Fermi Lab in Batavia IL, 60510, phone: 630-840-3000.
#  $RCSfile: pingNodes.sh,v $
#  $Revision: 1.1 $
#  $Date: 2005/02/11 03:02:29 $

#  from Markus' email:
#  - ping a list of nodes and make a resonable output on there status

set -u

USAGE="\
  usage: $0 <node_list>
example: $0 b0evb{02-16}
"

if [ ! "${1-}" ];then echo "$USAGE"; exit; fi

cleanup() { rm -f /tmp/rgang.$$; }
trap cleanup 1 2 15

if hash rgang 2>/dev/null;then
    # --rsh="ssh -n" and/or --do-local do not work (to eliminate password
    # prompt for b0evb01 from b0evb01)
    rgang -n --rshto=5 --err-file=/tmp/rgang.$$ --do-local --rsh="ssh" "$1" 'echo `hostname` OK' 2>/dev/null
    if [ -s /tmp/rgang.$$ ];then
        echo problems with:
        cat /tmp/rgang.$$
    fi
    cleanup
else
    echo "$0: critical component \"rgang\" not found; Did you forget to setup?"
fi
