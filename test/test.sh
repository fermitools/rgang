#! /bin/sh
#   This file (test.sh) was created by Ron Rechenmacher <ron@fnal.gov> on
#   Dec 19, 2001. "TERMS AND CONDITIONS" governing this file are in the README
#   or COPYING file. If you do not have such a file, one can be obtained by
#   contacting Ron or Fermi Lab in Batavia IL, 60510, phone: 630-840-3000.
#   $RCSfile: test.sh,v $
#   $Revision: 1.70 $
#   $Date: 2021/12/09 13:20:41 $
set -u
if [ "${1-}" = -x ];then set -x; shift; fi

# NOTE: this path is for the remote nodes when --nway!=0, to get the
#       correct local rcp/rsh, the local path needs to be set accordingly
#       and path to python remote and local
pypath=`dirname \`which python\``
PATHOPT="--path=/tmp:$pypath"
case `hostname` in
tststnd*)
    # try to test python frozen (binary) version. NOTE: IT SHOULD BE A 32bit
    # VERSION; if remote systems are 64bit, they must have 32bit compatible
    # libs installed!
    if [ -x ../bin/rgang ];then RGANG=../bin/rgang
    else                        RGANG=../bin/rgang.py; fi
    RSHOPT="--rsh=ssh -xK"
    RCPOPT="--rcp=scp"
    # copy ~test~ wants "local" node include, but it can be anywhere
    #nodespec="`hostname`,flxi04{,,}{,,}"
    nodespec="flxi03{,,}{,,},`hostname`"
    # DO NOT TEST "big_*output" IF BINARY FILE.
    # CURRENT "ISSUE" WITH RGANG -- it kind-of expected TEXT (lines) on stdout.
    # Could investigate why I do not find the "connects" and why I get
    # "Killed by signal 3" when I do the C-\ (which does send signal 3, but it
    # shouldn't _kill_ anything).
    most="base version stdout stderr stdin quote mach_id err_file other copy"
    ;;
work*)
    # try to test python 2.2.3 frozen (binary) version on fnapcf
    RGANG=../bin/rgang.py
    RSHOPT="--rsh=ssh -xK"
    RCPOPT="--rcp=scp"
    # copy ~test~ wants "local" node include, but it can be anywhere
    #nodespec="`hostname`,flxi03{,,}{,,}"
    nodespec="flxi03{,,}{,,},`hostname`{,}"
    # DO NOT TEST "big_*output" IF BINARY FILE.
    # CURRENT "ISSUE" WITH RGANG -- it kind-of expected TEXT (lines) on stdout.
    # Could investigate why I do not find the "connects" and why I get
    # "Killed by signal 3" when I do the C-\ (which does send signal 3, but it
    # shouldn't _kill_ anything).
    most="base version stdout stderr stdin quote mach_id err_file other copy"
    ;;
*)
    # should only _test_ frozen version on system where it is known to work 
    # (i.e. nodespec localhost only); if unsure, best to just stick with
    # python version (rgang.py)
    if [ -x ../bin/rgang ];then RGANG=../bin/rgang
    else                        RGANG=../bin/rgang.py; fi
    RGANG=../bin/rgang.py
    #RSHOPT="--rsh=/usr/bin/rsh"
    #RSHOPT="--rsh=ssh -xK"
    RSHOPT=
    #RCPOPT="--rcp=/usr/bin/rcp"
    RCPOPT=
    host=`hostname`
    ##nodespec="$host{,,,,,,,,,}"
    nodespec="localhost{,,,}{,,}"
    ##nodespec="$host{,,}"
    #most="base version"
    most="base version stdout stderr stdin quote mach_id err_file other copy big_output input_to_branches ctrl_c big_ssh_output"
    ;;
esac



NN="-n"
# (testing in kerberos environment) may need to (can be done from interactive session) export RGANG_PY_RSHTO=20
if [ ! "${RGANG_PY_RSHTO-}" ];then export RGANG_PY_RSHTO=20;fi

opts_w_args='add|nodes|rgang'
opts_wo_args='v|q'
USAGE="\
   usage: $0 [opts] <all|most|test [test]...>
examples: (time $0 all)2>&1|tee test.sh-all.out.txt  # probably want to do this
          $0 --rgang ../bin/rgang.py most
          RGANG_RSH='/bin/ssh -x' ./test.sh --rgang ../bin/rgang.py most
          $0 --add \"fnapcf{,,}\" all
          $0 --nodes \"fnapcf{,,}{,}\" all
opts_w_args=\"$opts_w_args\"
opts_wo_args=\"$opts_wo_args\"
Quick note: ssh-agent (if used) will likely not work with multiple/simultaneous ssh clients, i.e. this test.
tests are:
`grep '^ *[a-z_]\{2,\})' $0 | sed 's/)//'`
\"most\" will not do invalid_rsh and big_ssh (which is [likely] 256+ nodes).
"
while op=`expr "${1-}" : '-\(.*\)'`;do
    opts="${opts-} -$op"; shift
    if xx=`expr "$op" : '-\(.*\)'`;then
        op=$xx
    else
        op=`echo "$op" | perl -e '$_=<>;$_=~s/(.)/"$1" /g;print "$_"'`
    fi
    eval "for opt in $op;do
        case \$opt in
        \\?|h|help) echo \"\$USAGE\"; exit 0;;
        $opts_wo_args)
            eval opt_\`echo \$opt |sed -e 's/-/_/g'\`=1;;
        $opts_w_args)
            if [ $# = 0 ];then echo \"option \$opt requires argument\"; exit 1; fi
            eval opt_\`echo \$opt|sed -e 's/-/_/g'\`=\"'\$1'\"
            opts=\"\$opts '\$1'\"; shift;;      # tricky part A
        *)  echo \"invalid option: \$opt\";echo \"\$USAGE\"; exit 1;;
        esac
    done"
done

if [ "${1-}" ];then test=$1
else echo "$USAGE";exit;fi

if [ "${opt_nodes-}" ];then
    nodespec=$opt_nodes
fi
if [ "${opt_add-}" ];then
    nodespec="$nodespec,${opt_add-}"
fi
if [ -n "${opt_rgang-}" ];then
    RGANG=$opt_rgang
fi
expect_nodes=`$RGANG --list $nodespec | wc -l`
if [ "$1" != most -a "$1" != all ];then
    ps h -p$$
    echo
fi

vecho()
{   if [ "${opt_v-}" ];then echo "$@";fi
}
qecho()
{   if [ "${opt_q-}" = '' ];then echo "$@";fi
}

cmd()
{   tail=2; quiet="${opt_q-}"
    while expr "$1" : - >/dev/null;do case "$1" in
        -x) setx=1;shift;;
        -t) tail=$2;shift 2;;
        -q) quiet=1;shift;;
    esac; done
    cmd_str=''
    for arg in "$@";do
        cmd_str="$cmd_str '$arg'"
    done
    qecho "executing: $cmd_str >|stdout 2>|stderr"
    if [ -n "${setx-}" ];then set -x;fi
    if [ -n "$quiet" ];then "$@" >stdout 2>stderr; status=$?
    else               time "$@" >stdout 2>stderr; status=$?; fi
    test $tail -gt 0 && tail -$tail stderr
    if [ -n "${setx-}" ];then set +x; unset setx;fi
    return $status
}

#
#  Basic plan
#        $RGANG $RCPOPT -c "$nodespec" $RGANG /tmp
#        PATHOPT="--path=/tmp"
#        do tests
#        $RGANG $PATHOPT "$nodespec" "rm -f /tmp/`basename $RGANG`"
#
test_base()
{
    if grep "^[^#]*`hostname`" /etc/hosts >/dev/null;then
        : OK
    else
        echo 'hostname not found in /etc/hosts -- this will'
        echo 'cause excessive socket use which will result in the'
        echo '    rcmd: socket: All ports in use'
        echo 'error.'
        echo 'An rgang cmd to 12 hosts with --nway=2 will use 40-ish sockets'
        echo 'when hostname is not in /etc/hosts and just over 20 if it is.'
        echo 'The situation is made worse when hostname is not fully qualified'
        echo 'and the system has to try multiple domains.'
        echo 'The numbers for the default --nway=200 are not bad -- mainly it'
        echo 'is the new invocations of python that result when the --nway value'
        echo 'is much smaller than the number of nodes.'
        echo 'NOTE: xinetd.d/rsh should have "instances" and "per_source" = UNLIMITED'
        #exit 1
        echo 'press enter to continue.'; read ans
    fi

    # trying to support --rgang 'python3 ../bin/rgang.py'
    rfile=`echo "$RGANG" | sed -e 's/python[23]* *//'`
    cmd $RGANG $PATHOPT $RCPOPT -c "$nodespec" $rfile /tmp
    status=$?
    if [ $status -ne 0 ];then
        echo ERROR with base copy; exit 1
    fi
    echo
    echo "if we get here then we can start testing some things..."
    echo
    echo "base command: $RGANG ${RSHOPT:+\"$RSHOPT\"} $PATHOPT $NN --nway=4 \"$nodespec\" 'echo \$RGANG_MACH_ID - hi'"
    echo
}

test_version()
{   echo "test version..."
    date
    cmd $RGANG --version
    if [ $? -ne 0 ];then echo test_version FAILURE;exit 1;fi
    cat stdout
}

test_stdout()
{
    echo
    echo "test stdout..."
    for nway in --nway=0 --nway=3 --nway=4;do
        cmd $RGANG                      ${RSHOPT:+"$RSHOPT"} $PATHOPT $NN $nway "$nodespec" "echo \$RGANG_MACH_ID - hi"
        #cmd $RGANG --tlvlmsk=0xffffffff ${RSHOPT:+"$RSHOPT"} $PATHOPT $NN $nway "$nodespec" "echo \$RGANG_MACH_ID - hi"
        status=$?
        if [ $status != 0 ];then
            echo "rgang command returned non-zero error status=$status"
            exit 1
        fi
        stdoutlc=`cat stdout | grep -v "^$" | wc -l`
        if [ $stdoutlc != $expect_nodes ];then
            echo "stdout wc -l $stdoutlc is not the expected $expect_nodes"
            exit 1
        fi
        echo "    stdout seems OK  (stdoutlc=$stdoutlc)"
    done
}

test_stderr()
{   echo
    echo "test stderr..."
    for nway in --nway=0 \
  --nway=2 --nway=4;do
        rm -f ~/localhost.localdomain.*.trc ./localhost.localdomain.*.trc
        tlvlmsk=--tlvlmsk=0  #x0180
        cmd $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT $NN $tlvlmsk $nway "$nodespec" "sh -c 'echo \$RGANG_MACH_ID - hi 1>&2'"
        status=$?
        if [ $status != 0 ];then
            echo "rgang command returned non-zero error status=$status"
            exit $status
        fi
        stdoutlc=`cat stdout | wc -l`
        if [ $stdoutlc != 0 ];then
            echo "stdout wc $stdoutlc is not the expected 0"
            exit 1
        fi
        stderrlc=`grep '^[0-9]* - hi$' stderr | wc -l`
        if [ $stderrlc != $expect_nodes ];then
            echo "stderr wc -l $stderrlc is not the expected $expect_nodes"
            exit 1
        fi
        echo "    stderr seems OK"
        echo "Note: with nodespec=\"localhost{,,,}{,,}\", sockets in TIME_WAIT at this"
        echo "point could be about 550. It is: `awk '/TCP:/{print $7}' /proc/net/sockstat`"
    done
}

test_stdin()
{   echo
    echo 'test stdin...'
    
    first_node=`$RGANG --list "$nodespec" | head -1`
    echo 'piping "hi" into:'
    echo hi | cmd -q $RGANG $first_node 'read x; echo $x'
    if [ "`cat stdout`" != hi -o "`cat stderr`" != '' ];then
        echo "stdout and/or stderr not as expected"
        exit 1
    fi
    echo 'now try cmd with stdin closed'
    echo there | cmd -q $RGANG $first_node 'echo hi' <&-
    if [ "`cat stdout`" != hi -o "`cat stderr`" != '' ];then
        echo "stdout and/or stderr not as expected"
        exit 1
    fi
    echo '    stdin seems OK'
}

#exit

######################################################################################################

test_quote()
{
    echo
    echo "test quoting:   rsh node csh -fc 'echo \"hi    there\"'"
    echo "                should produce: <blank>   (what gets to the remote shell is: csh -fc echo \"hi    there\")"
    echo "                Note: some node may or may not produce a (single) new-line with the above line"
    echo "       while:   rsh node \"csh -fc 'echo \\\"hi    there\\\"'\""
    echo "                should produce: hi    there"
    cmd $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT -n0 --nway=1 "$nodespec" csh -fc 'echo "hi    there"'
    status=$?
    if [ $status != 0 ];then
        echo "rgang command returned non-zero error status=$status"
        exit 1
    fi
    if grep hi stdout;then
        echo "stdout should not contain any words"
        exit 1
    fi
    
    >stdout.expect
    for nn in `$RGANG --list "$nodespec"`;do
        echo "hi    there" >>stdout.expect
    done
    cmd $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT -n0 --nway=1 "$nodespec" "csh -fc 'echo \"hi    there\"'"
    status=$?
    if [ $status != 0 ];then
        echo "rgang command returned non-zero error status=$status"
        exit 1
    fi
    if diff stdout stdout.expect;then
        :
    else
        echo "stdout file should be same as stdout.expect"
        exit 1
    fi
    cmd $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT -n0 --nway=1 "$nodespec" "csh -fc \"echo 'hi    there'\""
    status=$?
    if [ $status != 0 ];then
        echo "rgang command returned non-zero error status=$status"
        exit 1
    fi
    if diff stdout stdout.expect;then
        :
    else
        echo "stdout file should be same as stdout.expect"
        exit 1
    fi
    rm -f stdout.expect
}


######################################################################################################

test_mach_id()
{
    echo
    echo "testing \$RGANG_MACH_ID \$RGANG_PARENT_ID"
    cmd $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT -n0 --nway=1 "$nodespec" 'echo $RGANG_MACH_ID $RGANG_PARENT_ID'
    status=$?
    if [ $status != 0 ];then
        echo "rgang command returned non-zero error status=$status"
        exit 1
    fi
    other_node()
    {   x=0; while expr $x \< $expect_nodes >/dev/null;do
            echo $x ${prevx-} >>stdout.expect
            prevx=$x; x=`expr $x + 1`            
        done
    }

    hostname=`hostname`
    short_host=`expr $hostname : '\([^.]*\)'`
    local_ips=`ifconfig | sed -n '/inet /{s/.*net //;s/addr://;s/ .*//;H}; ${x;s/\n/|/g;p}'`
    ere1="localhost"
    ere2="$short_host$local_ips"   # NOTE: local_ips will have the ere "|"

    # see if "initiator" node is included and therefore will have a PARENT_ID and
    # therefore will show up as the PARENT_ID for the first node (which may be itself).
    # If it is in the list multiple times, it will be the first one.
    # (could use verbose option with --list to get mach_id)
    expected_first_parent=`$RGANG --list "$nodespec" | egrep -n "$ere1" | head -1 | sed 's/:.*//'`
    if [ -n "$expected_first_parent" ] && test $expected_first_parent -eq 1;then
        # turn line number into MACH/PARENT_ID
        expected_first_parent=`expr $expected_first_parent - 1`
    else
        expected_first_parent=`$RGANG --list "$nodespec" | egrep -n "$ere2" | head -1 | sed 's/:.*//'`
        if [ -n "$expected_first_parent" ];then
            # turn line number into MACH/PARENT_ID
            expected_first_parent=`expr $expected_first_parent - 1`
        fi
    fi

    >stdout.expect
    expect_out()
    {   prevx=$expected_first_parent
        x=0; while expr $x \< $expect_nodes >/dev/null;do
            echo $x $prevx
            prevx=$x; x=`expr $x + 1`
        done
    }
    expect_out >>stdout.expect
    if diff stdout stdout.expect;then
        echo "test of \$RGANG_MACH_ID \$RGANG_PARENT_ID OK"
    else
        echo "stdout file should be same as stdout.expect"
        exit 1
    fi
    rm -f stdout.expect
}   # test_mach_id


######################################################################################################

test_err_file()
{
    echo
    echo "now check --err-file  Note: because of rsh return status issues and also"
    echo "    shell (sh/csh) compatibility issues, the status for some of the node"
    echo "    will be just 0 or 1 (no-error or error) instead of the actual"
    echo "    command status (which, for error, may be other than 1)"

    rm -f err-file
    cmd $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT -n0 --nway=3 --err-file=err-file "$nodespec" 'ls .bashrcxxxxxx'
    status=$?
    if [ $status = 0 ];then
        echo "rgang command returned zero error status during --err-file test"
        echo "where the status is expected to be non-zero"
        exit 1
    fi
    if [ -f err-file ];then
        if [ `cat err-file | wc -l` = $expect_nodes ];then
            echo "--err-file OK"
        else
            echo "ERROR --err-file=err-file wc -l not $expect_nodes"
            exit 1
        fi
    else
        echo "ERROR --err-file=err-file not found as expected"
        exit 1
    fi

    rm -f err-file
    cmd $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT -n0 --nway=3 --err-file=err-file "$nodespec" \
        'test $RGANG_MACH_ID -ne 2 && true || false'
    status=$?
    if [ $status = 0 ];then
        echo "rgang command returned zero error status during --err-file test"
        echo "where the status is expected to be non-zero"
        exit 1
    fi
    if [ -f err-file ];then
        if [ `cat err-file | wc -l` = 1 ];then
            echo "--err-file OK"
        else
            echo "ERROR --err-file=err-file wc -l not $expect_nodes"
            exit 1
        fi
    else
        echo "ERROR --err-file=err-file not found as expected"
        exit 1
    fi

    rm -f err-file
}

######################################################################################################

test_other()
{
    for otherOpt in --nway=4 --nway=2 --nway=1 --combine --pty --do-local --serial;do
    ##for otherOpt in --do-local --serial;do
        echo
        echo "testing with \$otherOpt=$otherOpt"

        echo "test zero error status..."
        cmd $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT $NN $otherOpt "$nodespec" 'echo hi'
        status=$?
        if [ $status != 0 ];then
            echo "rgang command returned non-zero error status ($status) when zero error status was expected"
            exit 1
        fi
        echo "    error status seems OK"

        echo "test non-zero error status..."
        cmd $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT $NN $otherOpt "$nodespec" 'ls /sdlkfjslk2223'
        status=$?
        if [ $status = 0 ];then
            echo "rgang command returned zero error status when non-zero error status was expected"
            exit 1
        fi
        echo "    error status seems OK"
    done

    echo "test different commands..."
    for command in "sleep 5 >&- 2>&- &";do
        cmd $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT $NN --nway=1 "$nodespec" $command
        status=$?
        if [ $status != 0 ];then
            echo "rgang command returned non-zero error status=$status"
            exit 1
        fi
        echo "    command seems OK"
    done
}

######################################################################################################

test_invalid_rsh()
{
    for nway in "" --nway=4;do
        echo "test non-zero error status..."
        cmd $RGANG --rsh=invalid_rsh $PATHOPT "$nodespec" 'ls /sdlkfjslk2223'
        status=$?
        if [ $status = 0 ];then
            echo "rgang command returned zero error status when non-zero error status was expected"
            exit 1
        fi
        if xx=`grep "Error execing invalid_rsh" stderr`;then
            if [ `echo "$xx" | wc -l` -eq $expect_nodes ];then
                : OK
            else
                echo "stderr does not contain the expected number of error lines ($expect_nodes)"
                exit 1
            fi
        else
            echo "stderr does not contain the expected output"
            exit 1
        fi
        echo "    error status seems OK"
    done
}

######################################################################################################

test_copy()
{
    echo
    echo "now a quick copy"
    echo
    echo "basic copy command: $RGANG ${RSHOPT:+\"$RSHOPT\"} $PATHOPT --nway=4 $RCPOPT -c \"$nodespec\" $RGANG /tmpxxxx"
    echo

    echo "1st check error"
    cmd $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT $RCPOPT -c "$nodespec" $RGANG /tmpxxxx
    status=$?
    if [ $status = 0 ];then
        echo "rgang -c command returned zero error status when non-zero expected"
        exit 1
    fi
    echo "error copy OK"

    echo "now check various copies"
    for otherOpt in --nway=4 --nway=1 --serial;do
        echo
        echo "testing with $otherOpt"

        cmd $RGANG         ${RSHOPT:+"$RSHOPT"} $PATHOPT $otherOpt $RCPOPT -c "$nodespec" $RGANG /tmp/`basename $RGANG`x
        status=$?
        if [ $status != 0 ];then
            echo "rgang -c command returned non-zero error status $status"
            exit 1
        fi
        echo "copy OK"
    done

    if diff $RGANG /tmp/`basename $RGANG`x;then
        # they are the SAME
        cmd $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT "$nodespec" "rm -f /tmp/`basename $RGANG`x"
        status=$?
        if [ $status != 0 ];then
            echo "final \"rgang rm\" command returned non-zero error status $status"
            exit 1
        fi
    else
        echo "copy source $RGANG differs from dest /tmp"
        exit 1
    fi
}   # test_copy

######################################################################################################

test_big_output()
{
    echo
    echo "testing a lot of output (catting the big rgang python source file :)"
    echo

    if [ ! -f /tmp/`basename $RGANG` ];then
        echo do base first;exit 1;
    fi

    size_rgang=`/bin/ls -l $RGANG | awk '{print $5}'`
    expect_size=`expr $size_rgang \* $expect_nodes`
    for nway in "" --nway=5;do
        cmd $RGANG ${RSHOPT:+"$RSHOPT"} -n0 $PATHOPT $nway "$nodespec" "cat /tmp/`basename $RGANG`"
        status=$?
        if [ $status != 0 ];then
            echo "Error with big copy"; exit 1
        fi
        size_bytes=`/bin/ls -l stdout | awk '{print $5}'`
        if [ $size_bytes -ne $expect_size ];then
            echo "stdout_size($size_bytes) != rgang_size($size_rgang) * expect_nodes($expect_nodes)"
            exit 1
        fi
    done
    echo big_output OK
}   # test_big_output

######################################################################################################

test_input_to_branches()
{
    echo
    echo "testing (stdin) input to branches"
    echo

    datespec=`date +%m%d%H%M`
    for nway in "" --nway=3;do
        rm -f /tmp/rgang.$datespec.*
        echo testing with nway=$nway
        cat $RGANG | $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT -n0 --input-to-all-branches $nway "$nodespec" \
            "cat >/tmp/rgang.$datespec.\$RGANG_MACH_ID"
        #cat $RGANG | $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT --tlvlmsk=0x4000200 -n0 --input-to-all-branches $nway "$nodespec" \
        #    "cat >/tmp/rgang.$datespec.\$RGANG_MACH_ID;sleep 2"
        xx=0
        while [ $xx -lt $expect_nodes ];do
            num=`expr $xx + 1`
            node=`$RGANG --list "$nodespec" | sed -n ${num}p`
            case $node in
            localhost|127.0.0.*|`hostname`) ;;
            *)  echo "skipping non-local host $node"
                xx=$num
                continue;;
            esac
            if out=`diff $RGANG /tmp/rgang.$datespec.$xx`;then
                :
            else
                echo diff $RGANG /tmp/rgang.$datespec.$xx
                echo "$out" | head
                echo ...
                echo 'files are different'
                exit 1
            fi
            xx=$num
        done
    done
    rm -f /tmp/rgang.$datespec.*
}   # test_input_to_branches

######################################################################################################

test_no_remote_rgang()
{
    :

}   # test_no_remote_rgang

######################################################################################################

test_ctrl_c()
{
    echo
    echo "test double control-C"
    echo
    echo '
Note: (double) control-C functionality when --nway is less than the number of
nodes is "iffy". One would perhaps hope that a control-C (SIGINT) of an rsh/ssh would
cause a control-c (SIGINT) signal to be propagated to the remote command.
That is what seems to happen when I do something like:
   $ rsh localhost rsh localhost rsh localhost '"'"'echo hi;sleep 30;echo there'"'"'
   hi
   ^C
   $ ps auxww | grep '"'"' sleep '"'"'

But the rgang/test script environment is complicated.
The command:
rgang --rsh=/usr/bin/rsh --nway=1 "localhost{,,,}{,,,}" '"'"'echo $RGANG_MACH_ID - hi;sleep 5;sleep `expr 4 \* \( 16 - $RGANG_MACH_ID \)`;echo there'"'"'
seems to work interactively, but leave lingering/defunct processes when run from this
script.
'



    ignore_pythons=`ps auxw | awk '/python/{print $2}'`
    ignore_pythons_ere="(`echo $ignore_pythons | sed 's/ /|/g'`)"

    pstree_parse()
    {   perl -ne '
        if (/(.*)'$1'/)
        {   print;
            $offset=length($1);
            $offstr="."x$offset;
            $re="${offstr}.*[+|]";
            #print "\$re=$re\n";
            while (/$re/)
            {   $_=<>;print;
            }
        }
'
    }
    descendants()
    {   pid=$1
        xx=`pstree -p $pid`
        echo "$xx" >&2
        echo "$xx" | sed -n 's/[^()]*(\([0-9]*\))/\1\
/g;H; ${ x; s/^\n*//;s/\n*$//;s/\n\n/\n/g;p;}'
    }
    pstree_python()
    {   pst=`pstree -p | egrep -v "$ignore_pythons_ere"`
        echo "$pst" | pstree_parse python | head -8
        if [ "${opt_v-}" ];then echo "$pst" | pstree_parse python | tail -n+9;fi
    }
    send_rgang_ctrl_c()
    {   parent=$1
        if [ "${2-}" ];then sleep $2
        else             sleep 7.5;fi
        pstree_python
        xxx=`descendants $parent 2>&1`
        #echo "xxx=$xxx"
        rgang_pid=`echo "$xxx" | sed -n '/python/{s/.*python[2-9]*(//;s/).*//;p}'`
        echo rgang_pid=$rgang_pid
        if [ "$rgang_pid" ];then
            kill -INT $rgang_pid
            sleep .5
            kill -INT $rgang_pid
        fi
    }
    rgangs=`ps aux | grep "$USER.*[p]ython.*rgang"`
    rgangs_cnt=`echo "$rgangs" | grep -v '^$' | wc -l`
    if [ $rgangs_cnt != 0 ];then
        echo "There appears to be rgangs ($rgangs_cnt) running on this node which is unexpected"
        echo "rgangs:"
        echo "$rgangs"
        exit 1
    fi
    tlvlmsk=
    #tlvlmsk=--tlvlmsk=0x40000580
    if [ $test != all ];then PATHOPT=;fi

    #for nway_nodes in "localhost{,,,}{,,,}{,,}";do # OK
    #for nway_nodes in        "--nway=1 localhost{,,,}{,}";do # OK
    #for nway_nodes in        "--nway=1 localhost{,,,}{,,}";do # issue sometimes
    #for nway_nodes in                                 "--nway=3 localhost{,,,}{,,}";do # OK
    #for nway_nodes in                                 "--nway=3 localhost{,,,}{,,,}";do # issue
    for nway_nodes in "localhost{,,,}{,,,}{,,}" "--nway=1 localhost{,,,}{,}" "--nway=3 localhost{,,,}{,,}";do

        rm -f ~/localhost.*.trc ./localhost.*.trc

        xx=10; while xx=`expr $xx - 1`;do
            num_waits=`netstat -t | grep WAIT | wc -l`
            echo 'loop start: netstat -t | grep WAIT | wc -l  ==>' $num_waits
            test $num_waits -lt 60 && break
            echo "wait 20 seconds for WAIT's to decrease"; sleep 20
        done
        if [ $num_waits -ge 60 ];then
            echo "waits too high too long"; exit 1
        fi

        send_rgang_ctrl_c $$ &
        t0=`date +%s`

        num_nodes=`$RGANG --list $nway_nodes | wc -l`; echo num_nodes=$num_nodes

        cmd -t 4 -q $RGANG ${RSHOPT:+"$RSHOPT"} $PATHOPT ${tlvlmsk-} $nway_nodes \
        'echo $RGANG_MACH_ID - hi;sleep 5;sleep `expr 4 \* \( '$num_nodes' - $RGANG_MACH_ID \)`;echo there'
#        'echo $RGANG_MACH_ID - hi;sleep 5;sleep 5;echo there'

        status=$?

        rgangs=`ps aux | grep "$USER.*[p]ython.*rgang" | wc -l`
        echo rgangs=$rgangs
        pstree_python
        xx=11;while xx=`expr $xx - 1`;do
            sleep 3
            tnow=`date +%s`
            rgangs=`ps aux | grep "$USER.*[p]ython.*rgang" | wc -l`
            echo "rgangs=$rgangs   seconds since start=`expr $tnow - $t0`"
            if [ $rgangs -eq 0 ];then break;fi
            pstree_python
        done
        if [ $rgangs != 0 ];then
            pids=`pstree -p | egrep -v "$ignore_pythons_ere" | pstree_parse python`
            pids=`echo $pids | sed 's/[^(]*(/ /;s/)[^(]*(/ | /g;s/).*/ /'`
            echo "pids=$pids"
            ps alxmw | grep -v 'grep' | egrep "$pids"
            echo "There appears to be rgangs ($rgangs) running on this node which is unexpected"
            echo "press control-C to exit before 30 sleep expires";sleep 30
            tnow=`date +%s`
            rgangs=`ps aux | grep "$USER.*[p]ython.*rgang" | wc -l`
            echo "rgangs=$rgangs   seconds since start=`expr $tnow - $t0`"
            exit 1
        fi
        echo test_ctrl_c OK
    done
}   # test_ctrl_c

######################################################################################################

test_big_ssh_output()
{
    echo
    echo "test huge output --"
    echo "a lot of output (catting the big rgang python source file :)"
    echo "with a lot of nodes -- there actually may be some errors so"
    echo "I really can not count bytes"
    echo "Note (2010.05.06): to avoid:"
    echo "  ssh_exchange_identification: Connection closed by remote host"
    echo "change /etc/sshd_config-localhost OR /etc/sshd_config-127.0.0.1"
    echo "MaxStartups from default 10 to 100"
    echo "Note: system (if all localhost nodes used) should have about 3 GB RAM."

    rsh_opt="--rsh=ssh -xKF/dev/null -oStrictHostKeyChecking=no"
    if ps auxw | egrep '[s]shd -f /etc/ssh/sshd_config-(localhost|127.0.0.1)';then
        :
    else
        echo 'WARNING - localhost sshd not running'
        #exit 1
    fi
    if [ ! -f /tmp/`basename $RGANG` ];then
        echo do base first;exit 1;
    fi

    for nway_nodes in "--nway=20 $nodespec{,,,,,,,}";do
    #for nway_nodes in "--nway=20 $nodespec";do
        echo
        nodes_num=`$RGANG --list $nway_nodes | wc -l`
        echo nodes_num=$nodes_num
        cmd $RGANG "$rsh_opt" $PATHOPT -n0 $nway_nodes "cat /tmp/`basename $RGANG`"
        status=$?
        if [ $status != 0 ];then
            echo "Error with big (huge) ssh output"; exit 1
        fi
        ls -l stdout
    done
    echo   big_ssh_output OK
}   # test_big_ssh_output

######################################################################################################

test_big_ssh()
{
    echo
    echo "test big ssh"
    echo
    echo "Note: currently (2008.05.23) with the localhost ssh setup on"
    echo "my laptop, it seems if too many ssh's happen too fast, a"
    echo "  ssh_exchange_identification: Connection closed by remote host"
    echo "error happens."
    echo "Seem things work better with a lower --nway and a .rgangrc with:"
    echo "    sleep \`python -c 'import random;print random.randint(0,70)/10.0'\`"
    echo
    echo "2010.05.06 - changing /etc/sshd_config-127.0.0.1 MaxStartups from the default"
    echo "   value of 10 really helps.  May also want to try increasing the value of"
    echo "   /proc/sys/net/core/somaxconn from the default of 128 up to 512 or so."
    echo
    echo "To just print graphs, use:"
    echo "    ./test.sh -q big_ssh"
    echo

    if ps auxw | egrep '[s]shd -f /etc/ssh/sshd_config-(localhost|127.0.0.1)' >/dev/null;then
        :
    else
        echo 'WARNING - sshd with "-f *-localhost" not running'
        #exit 1
    fi

    if [ -f $HOME/.rgangrc ];then keep_rgangrc=1;else keep_rgangrc=;fi
    if [ -f $HOME/.rgangrc ] && grep 'sleep.*python' $HOME/.rgangrc >/dev/null;then
        sed -i -e '/^ *#sleep .*random/s/#s/s/' $HOME/.rgangrc
    else
        echo "sleep \`python -c 'import random;print(random.randint(0,70)/10.0)'\`" >>$HOME/.rgangrc
    fi
    echo "contents of \$HOME/.rgangrc (between \"-----------\"):"
    echo "-----------"
    cat $HOME/.rgangrc
    echo "-----------"
    echo

#  "cd $PWD;echo \$RGANG_MACH_ID - hi | tee rgang_test/\$RGANG_MACH_ID"\
#  "cd $PWD;echo \$RGANG_MACH_ID - hi | tee rgang_test/\$RGANG_MACH_ID;sleep 4"\
#  "cd $PWD;echo \$RGANG_MACH_ID - hi | tee rgang_test/\$RGANG_MACH_ID;xx=3000;while xx=\`expr \$xx - 1\`;do :;done"\
#

    for rcmd in \
  "cd $PWD;echo \$RGANG_MACH_ID - hi | tee rgang_test/\$RGANG_MACH_ID"\
        ;do
        #for nway in --nway=5;do
        for nway in --nway=3 --nway=5 --nway=20;do
            rm -f plot.dat
            for nodes in\
  "localhost{,,,}{,,,}{,}"\
  "localhost{,,,}{,,,}{,,,}"\
  "localhost{,,,}{,,,}{,,,}{,}"\
  "localhost{,,,}{,,,}{,,,}{,,}"\
  "localhost{,,,}{,,,}{,,,}{,,,}"\
  "#localhost{,,,}{,,,}{,,,}{,,,,}"\
  "#localhost{,,,}{,,,}{,,,}{,,,,,}"\
  "#localhost{,,,}{,,,}{,,,}{,,,,,,}"\
  "#localhost{,,,}{,,,}{,,,}{,,,,,,,}"\
  "#localhost{,,,}{,,,}{,,,}{,,,,,,,,}"\
  "#localhost{,,,}{,,,}{,,,}{,,,,,,,,,}"\
                ;do  # 32 64 128 192 256 # 320 384 448 512 576 640 ...
                if expr "$nodes" : '#' >/dev/null;then continue; fi
                node_num=`$RGANG --list $nodes | wc -l`;vecho node_num=$node_num
                mkdir -p rgang_test
                rm -f localhost*.trc err-file rgang_test/*
                t0=`date +%s`
                cmd $RGANG --rsh="ssh -xKF/dev/null -oStrictHostKeyChecking=no" ${tlvlmsk-} $nway --err-file=err-file "$nodes" \
                    "$rcmd"
                t1=`date +%s`
                tdelta=`expr $t1 - $t0`
                qecho completed node_num=$node_num
                errors=`cat err-file | wc -l`;qecho errors=$errors
                oks=`/bin/ls rgang_test | wc -l`;qecho oks=$oks
                TIME_WAIT=`netstat -t | grep TIME_WAIT | wc -l`; qecho TIME_WAIT=$TIME_WAIT
                echo "$node_num $oks $errors $tdelta" >>plot.dat
                qecho "----------"
            done
            echo "
set key left
set xlabel \"(total) nodes in individual rgang command\"
set ylabel \"nodes withs\\nERR/OK\" #0,1
set title \"rgang command ($nway)\\nERR/OK vs. num_nodes\\ncmd_time vs. num_nodes\"
set ytics nomirror
set y2tics
set y2label \"rgang cmd\\ntime (seconds)\"
set term dumb
plot \"plot.dat\" u 1:2 t \" OK\",\
     \"plot.dat\" u 1:3 t \" ERR\",\
     \"plot.dat\" u 1:4 t \"time(s)\" axes x1y2
" | gnuplot
        done
    done
    TIME_WAIT=`netstat -t | grep TIME_WAIT | wc -l`; echo TIME_WAIT=$TIME_WAIT
    # rm plot.dat
    if [ "$keep_rgangrc" ];then
        sed -i -e '/^ *sleep .*random/s/s/#s/' $HOME/.rgangrc
    else
        rm -f $HOME/.rgangrc
    fi
}   # test_big_ssh


######################################################################################################

test $# -gt 1 && echo "Doing tests: $*"

while [ "${1-}" ];do
    test=$1;shift
    case $test in
    base)
        test_base;;
    version)
        test_version;;
    stdout)
        test_stdout;;
    stderr)
        test_stderr;;
    stdin)
        test_stdin;;
    quote)
        test_quote;;
    mach_id)
        test_mach_id;;
    err_file)
        test_err_file;;
    other)
        test_other;;
    invalid_rsh)
        test_invalid_rsh;;
    copy)
        test_copy;;
    big_output)
        test_big_output;;
    input_to_branches)
        test_input_to_branches;;
    ctrl_c)
        test_ctrl_c;;
    big_ssh_output)
        test_big_ssh_output;;
    big_ssh)
        test_big_ssh;;
    most)
        echo "From `hostname -s`, doing \"most\" tests..."
        echo "nodespec=$nodespec specifies $expect_nodes nodes"
        $0 --nodes "$nodespec" --rgang $RGANG $most
        _status=$?
        if [ $_status -eq 0 ];then
            echo "All is well"
        fi
        ;;
    all)
        tests=`grep '^ *[a-z_]\{2,\})' $0 | sed 's/).*//' | egrep -v ' (all|most)'`
        echo "From `hostname -s`, doing \"all\" tests: $tests"
        echo "nodespec=$nodespec specifies $expect_nodes nodes"
        test_completed=0
        for test in $tests;do
            $0 ${opt_rgang+--rgang $opt_rgang} $test
            if [ $? -ne 0 ];then echo test $test failed;exit 1;fi
            test_completed=`expr $test_completed + 1`
        done
        echo test_completed=$test_completed
        echo "Note: with nodespec=\"localhost{,,,}{,,}\", sockets in TIME_WAIT at this"
        echo "point could be about 550. It is: `netstat -t | grep TIME_WAIT | wc -l`"
        echo
        echo "All is well"
        ;;
    *)
        echo "unknown test"
        echo "$USAGE"; exit 1
    esac
done
status=$?
#rm -f stdout stderr
exit $status
