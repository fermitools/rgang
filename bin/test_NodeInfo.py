#!/bin/env python3
#   This file (test_NodeInfo.py) was created by Ron Rechenmacher <ron@fnal.gov> on
#   Jan 21, 2005. "TERMS AND CONDITIONS" governing this file are in the README
#   or COPYING file. If you do not have such a file, one can be obtained by
#   contacting Ron or Fermi Lab in Batavia IL, 60510, phone: 630-840-3000.
#   $RCSfile: test_NodeInfo.py,v $
#   $Revision: 1.2 $
#   $Date: 2025/01/14 21:52:08 $

import rgang

thisnode = rgang.NodeInfo()

print('thisnode.hostnames_l =',thisnode.hostnames_l)
print('thisnode.alias_l     =',thisnode.alias_l)

for node in ('acpr5','tststnd1','tststnd2','xxx'):
    if thisnode.is_me( node ): yn='yes'
    else:                      yn='no'
    print(node,yn)
