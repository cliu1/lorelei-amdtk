#!/usr/bin/python
#
#
#

import sys, os, pprint
from datetime import datetime

f_lst = sys.argv[1]
labeldir = sys.argv[2]
wf_tra = sys.argv[3]

file_lst = file(f_lst, 'r')

conv_lst = []
for line in file_lst:
  conv_lst.append(line.split()[0])

#pprint.pprint(conv_lst); sys.exit(0)
# ---------------------------------------------------------
# ---------------------------------------------------------
#labeldir = "/export/b04/cliu1/AMDTK-0/recipes/CHN_DEV_20160831/ploop_lbn_c10_T200_s3_g2_a3_b3/unigram_labels/"
wfile = file(wf_tra, 'w')

for conv in conv_lst:
  print >> wfile, conv,

  with open(labeldir + conv + ".lab", 'r') as infile:
    for line in infile:
      t1, t2, aud = line.split()
      print >> wfile, aud,

  print >> wfile, ""


wfile.close()
# ---------------------------------------------------------
#print str(datetime.now())


