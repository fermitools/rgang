#! /bin/sh
#   This file (rebootNodes.sh) was created by Ron Rechenmacher <ron@fnal.gov> on
#   Jan 22, 2005. "TERMS AND CONDITIONS" governing this file are in the README
#   or COPYING file. If you do not have such a file, one can be obtained by
#   contacting Ron or Fermi Lab in Batavia IL, 60510, phone: 630-840-3000.
#   $RCSfile: rebootNodes.sh,v $
#   $Revision: 1.1 $
#   $Date: 2005/02/11 03:02:29 $

#  from Markus' email:
#  - send a reboot to a list of node and check if they come up again.

set -u

USAGE="\
  usage: $0 <node_list>
example: $0 b0evb{02-16}
"

if [ ! "${1-}" ];then echo "$USAGE"; exit; fi

cleanup() { rm -f /tmp/rgang.errs.$$ /tmp/rgang.nodes.$$ /tmp/rgang.rebooted.$$; }
trap cleanup 1 2 15

waitmsg()   # $1 is seconds we have waited
{   if [ ! "${t0-}" ];then t0=`date +%s`;fi
    t1=`date +%s`
    echo -ne "Waiting for `cat /tmp/rgang.nodes.$$ | wc -l` nodes to reboot... `expr $t1 - $t0`\r"
    sleep $1
}

if hash rgang 2>/dev/null;then
    # reboot the nodes
    # to stagger the reboots, add --serial and a sleep before the reboot cmd
    rgang -n --rshto=5 --err-file=/tmp/rgang.errs.$$ --do-local --rsh="ssh" "$1" 'reboot' 2>/dev/null
    if [ -s /tmp/rgang.errs.$$ ];then
        echo problems with:
        cat /tmp/rgang.errs.$$
        rgang --list --skip /tmp/rgang.errs.$$ "$1" >/tmp/rgang.nodes.$$
    else
        rgang --list "$1" >/tmp/rgang.nodes.$$
    fi

    # now check if the list of good nodes comes back
    waitmsg 10
    x=11; while x=`expr $x - 1` && [ -s /tmp/rgang.nodes.$$ ];do
        rm -f /tmp/rgang.errs.$$
        rgang -n --rshto=5 --err-file=/tmp/rgang.errs.$$ --do-local --rsh="ssh" /tmp/rgang.nodes.$$ 'echo `hostname` OK' 2>/dev/null
        if [ -s /tmp/rgang.errs.$$ ];then
            rgang --list --skip /tmp/rgang.errs.$$ /tmp/rgang.nodes.$$ >>/tmp/rgang.rebooted.$$
            cat /tmp/rgang.errs.$$ >/tmp/rgang.nodes.$$
            waitmsg 10
        else
            cat /tmp/rgang.nodes.$$ >>/tmp/rgang.rebooted.$$
            >/tmp/rgang.nodes.$$
        fi
    done
    echo
    if [ -s /tmp/rgang.rebooted.$$ ];then
        echo the following nodes rebooted
        cat /tmp/rgang.rebooted.$$ 
    fi
    if [ -s /tmp/rgang.nodes.$$ ];then
        echo the following nodes have yet to reboot
        cat  /tmp/rgang.nodes.$$
    else
        echo all nodes have rebooted successfully
    fi
    cleanup
else
    echo "$0: critical component \"rgang\" not found; Did you forget to setup?"
fi
