#!/bin/env python3
#   This file (test_expand.py) was created by Ron Rechenmacher <ron@fnal.gov> on
#   Jan 21, 2005. "TERMS AND CONDITIONS" governing this file are in the README
#   or COPYING file. If you do not have such a file, one can be obtained by
#   contacting Ron or Fermi Lab in Batavia IL, 60510, phone: 630-840-3000.
#   $RCSfile: test_expand.py,v $
#   $Revision: 1.2 $
#   $Date: 2025/01/14 21:52:08 $

import rgang
import sys

#rgang.g_opt['tlvlmsk']=1

for testSpec in ["{n-z}",
                 "{8-9}",
                 "{08-9}",
                 "{7-0xa}",
                 "{07-0xa}",
                 "{f-0x10}",
                 "{0f-0x10}",
                 "{8-0xa}",
                 "{08-0xa}",
                 "{1-3}{1-2}",
                 "abc{1-2}{8-10}",
                 "willBeErr{1-2}{8-010}",   # this should be an error
                 ]:
    sys.stdout.write('attempt expand of %22s:  '%('"'+testSpec+'"',)); sys.stdout.flush()
    xx = rgang.expand( testSpec )
    print("xx =",xx)
