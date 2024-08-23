#!/usr/bin/env python
#   This file (tst_pipe.py) was created by Ron Rechenmacher <ron@fnal.gov> on
#   Jun 23, 2003. "TERMS AND CONDITIONS" governing this file are in the README
#   or COPYING file. If you do not have such a file, one can be obtained by
#   contacting Ron or Fermi Lab in Batavia IL, 60510, phone: 630-840-3000.
#   $RCSfile: tst_pipe.py,v $
#   $Revision: 1.3 $
#   $Date: 2005/02/11 03:05:09 $

# to use:
""" 
dd if=/dev/zero bs=8192 count=1024 \
| strace -f -F -e trace=read,write -o tst_pipe.strace.txt tst_pipe.py

OR

dd if=/dev/zero bs=8192 count=1024 \
| strace -f -F -e trace=read,write -o tst_pipe.strace.txt tst_pipe.py 'cat >/dev/null'
OR

dd if=/dev/zero bs=8192 count=1024 \
| strace -f -F -e trace=read,write -o tst_pipe.strace.txt tst_pipe.py 'dd of=/dev/null bs=8192'

OR

dd if=/dev/zero bs=8192 count=1024 \
| strace -f -F -e trace=read,write -o tst_pipe.strace.txt tst_pipe.py 'exec cat >/dev/null'

OR

# to see process structure
(sleep 200;dd if=/dev/zero bs=8192 count=1024) \
| tst_pipe.py 'cat >/dev/null'


COMPARE/CONTRAST TO (rsh -- note: ssh does encryption which greatly effects xfer rate):

dd if=/dev/zero bs=8192 count=1024 \
| strace -f -F -e trace=read,write -o rsh.strace.txt /usr/bin/rsh -x -1 localhost 'cat >/dev/null'

AND

dd if=/dev/zero bs=8192 count=1024 \
| strace -f -F -e trace=read,write -o rgang.strace.txt rgang --rsh=/usr/bin/rsh localhost 'cat >/dev/null'

AND

dd if=/dev/zero bs=8192 count=1024 \
| strace -f -F -e trace=read,write -o rgang.strace.txt rgang --rsh=/usr/bin/rsh --input-to-all-branches 'localhost{,}' 'cat >/dev/null'

AND FINALLY

dd if=/dev/zero bs=8192 count=1024 \
| strace -f -F -e trace=read,write -o rgang.strace.txt rgang --rsh=/usr/bin/rsh --input-to-all-branches 'localhost{,}' 'strace -e trace=read,write -o rgang.$RGANG_MACH_ID.strace.txt cat >/dev/null'


ULTIMATELY COMPARING

# 100 MB xfer
time dd if=/dev/zero bs=8192 count=12800 | /usr/bin/rsh pp128 'cat >/dev/null'
AND
time dd if=/dev/zero bs=8192 count=12800 | rgnag --rsh=/usr/bin/rsh pp128 'cat >/dev/null'

Real examples:

/home/ron/work2/rgangPrj/rgang/test
fnapcf :^) time dd if=/dev/zero bs=8192 count=12800 | /usr/bin/rsh pp130 'cat >/dev/null'
12800+0 records in
12800+0 records out
0.11user 0.54system 0:09.08elapsed 7%CPU (0avgtext+0avgdata 0maxresident)k
0inputs+0outputs (139major+19minor)pagefaults 0swaps
/home/ron/work2/rgangPrj/rgang/test
fnapcf :^) time dd if=/dev/zero bs=8192 count=12800 | rgang --rsh=/usr/bin/rsh pp128 'cat >/dev/null'
12800+0 records in
12800+0 records out
0.05user 0.38system 0:09.26elapsed 4%CPU (0avgtext+0avgdata 0maxresident)k
0inputs+0outputs (139major+19minor)pagefaults 0swaps
/home/ron/work2/rgangPrj/rgang/test
fnapcf :^) time dd if=/dev/zero bs=8192 count=12800 | rgang --rsh=/usr/bin/rsh --input-to-all-branches pp130,pp128 'cat >/dev/null'
pp130= 12800+0 records in
12800+0 records out
0.05user 0.37system 0:18.38elapsed 2%CPU (0avgtext+0avgdata 0maxresident)k
0inputs+0outputs (139major+19minor)pagefaults 0swaps
pp128= /home/ron/work2/rgangPrj/rgang/test
fnapcf :^) time dd if=/dev/zero bs=8192 count=12800 | rgang --rsh=/usr/bin/rsh --input-to-all-branches --nway=2 pp130,pp128,pp135 'cat >/dev/null'
pp130= 12800+0 records in
12800+0 records out
0.03user 0.43system 0:32.12elapsed 1%CPU (0avgtext+0avgdata 0maxresident)k
0inputs+0outputs (139major+19minor)pagefaults 0swaps
pp128= pp135= /home/ron/work2/rgangPrj/rgang
fnapcf :^) 

I am concerned about the significant drop from 100/18.38=5.4406
to 100/32.12=3.1133 for this situation; if there was another node, would
understand:
                           +-------------+
            2 flows        |  switch     |  3 flows; 1 in, 2 out = 12/3=4 MB/s
    fnapcf --------------->|------------>|------------>
           --------------->|----.    ,---|<-----------   pp130
                           |    |    | ,-|<-----------
                           |    |    | | |
                           |    |    | | |
                           |    |    | `-|------------>  other node 
                           |    |    |   |
                           |    |    |   |
                           |    |    `---|------------>  pp128
                           |    |        |
                           |    |        |
                           |    `--------|------------>  pp135
                           |             |
                           +-------------+


"""
# Then less tst_cat.strace.txt

import os
import sys
import socket
import string

def mypipe():
    import socket                       # socket
    s1 = socket.socket( socket.AF_INET, socket.SOCK_STREAM )
    s1.bind( ('localhost',socket.INADDR_ANY) )
    s1.listen( 1 )
    s2 = socket.socket( socket.AF_INET, socket.SOCK_STREAM )
    s2.connect( s1.getsockname() )
    s3,addr = s1.accept()
    print 'closing s1.fileno()=%d'%(s1.fileno(),)
    s1.close()
    ret_fd2 = os.dup(s2.fileno())
    ret_fd3 = os.dup(s3.fileno())
    print 'returning %s %s'%((ret_fd2,ret_fd3),(s2.getsockname(),s3.getsockname()))
    s2.close()
    s3.close()
    return (ret_fd2,ret_fd3) # it doesn't matter which is read/write



# this routine needs:
g_opt={'tlvlmsk':0,'pty':''}
g_num_spawns = 0
def spawn( cmd, args, combine_stdout_stderr=0 ):
    import os                           # fork, pipe
    import pty                          # fork
    import string                       # split
    global g_num_spawns                 # keep track for total life of process
    
    g_num_spawns = g_num_spawns + 1
    cmd_list = string.split(cmd)    # support cmd='cmd -opt'

    # for stdin/out/err for new child. Note: (read,write)=os.pipe()
    if g_opt['pty']: pipe0 = [0,0]    ; pipe1 = [1,1];     pipe2 = os.pipe()
    else:            pipe0 = os.pipe(); pipe1 = os.pipe(); pipe2 = os.pipe()
    #else:            pipe0 = mypipe(); pipe1 = mypipe(); pipe2 = mypipe()
    
    if g_opt['pty']: pid,fd = pty.fork()
    else:            pid    =  os.fork()
    
    if pid == 0:
        #child
        # combining stdout and stderr helps (when simply printing output)
        # get the output in the same order
        if combine_stdout_stderr: os.dup2( pipe1[1], 2 ); os.close( pipe2[1] )#; TRACE( 20, "child close %d", pipe2[1]) # close either way as we
        else:                     os.dup2( pipe2[1], 2 ); os.close( pipe2[1] )#; TRACE( 20, "child close %d", pipe2[1])  # are done with it.
        if g_opt['pty']:
            pass                        # all done for use in pyt.fork() (except our combining above)
        else:
            os.close( pipe0[1] )#; TRACE( 20, "child close %d", pipe0[1] )
            os.close( pipe1[0] )#; TRACE( 20, "child close %d", pipe1[0] )
            os.close( pipe2[0] )#; TRACE( 20, "child close %d", pipe2[0] )
            os.dup2( pipe0[0], 0 ); os.close( pipe0[0] )#; TRACE( 20, "child close %d", pipe0[0] )
            os.dup2( pipe1[1], 1 ); os.close( pipe1[1] )#; TRACE( 20, "child close %d", pipe1[1] )
        for ii in range(3,750):  # if default nway=200, and there are 3 fd's per process...
            try: os.close(ii)#; TRACE( 20, "child successfully closed %d", ii )
            except: pass
                        
        os.execvp( cmd_list[0], cmd_list+args )
        # bye-bye python
        pass
    #parent
    #TRACE( 20, 'spawn: pid=%d p0=%s p1=%s p2=%s execvp( %s, %s )', pid, pipe0, pipe1, pipe2, cmd_list[0], cmd_list+args )
    if g_opt['pty']:
        pipe0[1] = fd               # stdin  (fd is read/write and only valid in parent; pty takes care of child stdin )
        pipe1[0] = fd               # stdout (fd is read/write and only valid in parent; pty takes care of child stdout )
        os.close( pipe2[1] )        # parent doesn't need to write to child's stderr (pty does not take care of stderr)
    else:
        os.close( pipe0[0] )        # parent doesn't need to read from child's stdin
        os.close( pipe1[1] )        # parent doesn't need to write to child's stdout
        os.close( pipe2[1] )        # parent doesn't need to write to child's stderr
    child_stdin  = pipe0[1]
    child_stdout = pipe1[0]
    if combine_stdout_stderr: child_stderr = None
    else:                     child_stderr = pipe2[0]
    return pid,child_stdin,child_stdout,child_stderr
    # spawn



def myread( ifd, siz ):
    import select
    import os
    ss = os.read( ifd, siz )
    inbytes = len( ss )
    if inbytes != siz:
        ready = select.select( [ifd], [], [], 0 )
        while ready[0]:
            sss = os.read( ifd, siz-inbytes )
            if not sss: break
            ss = ss + sss
            inbytes = inbytes + len(sss)
            if inbytes == siz: break
            ready = select.select( [ifd], [], [], 0 )
    return (ss)



#STDIN_RDSZ = 512
STDIN_RDSZ = 8192

if len(sys.argv[1:]):
    # assume command given
    command = string.join(sys.argv[1:])
else:
    command = 'exec /bin/dd of=/dev/null bs=%d'%(STDIN_RDSZ,)

print 'my pid is',os.getpid()
ifd  = sys.stdin.fileno()
ofds = []
pids = []
for child in range(2):
    pid,child_stdin,child_stdout,child_stderr = spawn( '/bin/sh',['-c',command] )
    print 'child pid is',pid,' and fd is',child_stdin
    ofds.append( child_stdin )
    pids.append( pid )


ss = os.read( ifd, STDIN_RDSZ ) # initial read
#ss = myread( ifd, STDIN_RDSZ ) # initial read
inbytes  = len( ss )
while inbytes:

    for ofd in ofds:
        bytes_written = os.write( ofd, ss )
        while bytes_written < inbytes:
            bytes_this_write = os.write( br_sdtin, ss[bytes_written:] )
            bytes_written = bytes_written + bytes_this_write

    ss = os.read( ifd, STDIN_RDSZ ) # subsequent reads
    #ss = myread( ifd, STDIN_RDSZ ) # subsequent reads
    inbytes  = len( ss )

# clean up
for child_idx in range(len(ofds)):
    os.close( ofds[child_idx] )
    print 'waitpid for', pids[child_idx]
    opid,sts = os.waitpid( pids[child_idx], 0 )
    print 'returned'
