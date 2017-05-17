#!/usr/bin/python
#
# featurize file into libsvm format
#

import sys, pprint
import pickle
from datetime import datetime

# ----------------------------------------------------------------------------
BOC = "<s>"
EOC = "</s>"
OOV = "<OOV>"
FS = "#"

# ---------------------------------------------------------
def make_feat(feat, ndim, label):
  line = label
  for dim in range(1, ndim + 1):
    if feat.has_key(dim):
      line = line + " " + str(dim) + ":" + str(feat.get(dim))

  return line
# ---------------------------------------------------------
def write2feats(file_feat, line, ngram_map, label):

  ndim = len(ngram_map)
  feat = {}

  x = BOC; y = BOC
  for z in line:
    #yz = y + FS + z
    xyz = x + FS + y + FS + z

    #if ngram_map.has_key(z) == False or ngram_map.has_key(yz) == False or \
    if ngram_map.has_key(xyz) == False:
      print "KeyError"
      print line
      sys.exit(1)

    #feat[ngram_map[z]] = feat.get(ngram_map[z], 0) + 1
    #feat[ngram_map[yz]] = feat.get(ngram_map[yz], 0) + 1
    feat[ngram_map[xyz]] = feat.get(ngram_map[xyz], 0) + 1

    x = y; y = z


  print >> file_feat, make_feat(feat, ndim, label)
# ---------------------------------------------------------
# main
# ---------------------------------------------------------
f_tra = sys.argv[1] #f_tra = "decode.tra"
wf_pickle = sys.argv[2]
wf_feats = sys.argv[3]

file_tra = file(f_tra)

conv2line = {} # TUR_001_001 : [1, 2, 3]
conv_lst = []

for line in file_tra:
  inline = line.strip().split()
  conv = inline[0].split("-")[0]

  if conv not in conv_lst:
    conv_lst.append(conv)
    conv2line[conv] = []

  conv2line[conv].extend(inline[1:])

file_tra.close()

#pprint.pprint(conv_lst); print conv2line; #sys.exit(0)
# ---------------------------------------------------------

ngram_map = {} # ngram : idx (from 1)

for conv in conv_lst:
  conv2line[conv].append(EOC)
  line = conv2line[conv]

  x = BOC; y = BOC
  for z in line:
    #if ngram_map.has_key(z) == False:
    #  ngram_map[z] = len(ngram_map) + 1 # index from 1

    #yz = y + FS + z
    #if ngram_map.has_key(yz) == False:
    #  ngram_map[yz] = len(ngram_map) + 1

    xyz = x + FS + y + FS + z
    if ngram_map.has_key(xyz) == False:
      ngram_map[xyz] = len(ngram_map) + 1

    x = y; y = z

# write a dictionary file
wfile_pickle = open(wf_pickle, 'wb')
pickle.dump(ngram_map, wfile_pickle)
wfile_pickle.close()

print "ngram DIM:", len(ngram_map)
#pprint.pprint(ngram_map); #sys.exit(0)
# ---------------------------------------------------------
# ---------------------------------------------------------
wfile_feats = file(wf_feats, 'w') #wfile_feats = file("svm.feats", 'w')

for conv in conv_lst:
  line = conv2line[conv]

  write2feats(wfile_feats, line, ngram_map, conv)

# ---------------------------------------------------------
#print str(datetime.now())

