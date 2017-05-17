#!/usr/bin/python
#
#
#

import sys, os, pprint
import random, copy
import pickle
from datetime import datetime

import numpy as np

from sklearn.preprocessing import MultiLabelBinarizer
from sklearn.multiclass import OneVsRestClassifier

from sklearn.feature_extraction.text import TfidfTransformer 
from sklearn.linear_model import SGDClassifier

from sklearn.metrics import average_precision_score

# ----------------------------------------------------------
# GLOBALS
# ----------------------------------------------------------
label2int = {"Civil Unrest or Wide-spread Crime" : 0,  
  "Elections and Politics" : 1,
  "Evacuation" : 2,
  "Food Supply" : 3,
  "Urgent Rescue" : 4,
  "Utilities, Energy, or Sanitation" : 5,
  "Infrastructure" : 6,
  "Medical Assistance" : 7,
  "Shelter" : 8,
  "Terrorism or other Extreme Violence" : 9,
  "Water Supply" : 10, 
  "out-of-domain" : 11} 

int2label = {v: k for k, v in label2int.iteritems()}

# ----------------------------------------------------------
# ----------------------------------------------------------
# main
# ----------------------------------------------------------
# ----------------------------------------------------------
def main():
  f_utt2label = sys.argv[1] 
  f_pkl = sys.argv[2]
  f_feats = sys.argv[3]
  wdir = sys.argv[4]

  ##
  file_utt2label_train = open(f_utt2label, "r")
  lines = file_utt2label_train.readlines()
  file_utt2label_train.close()

  utt_lst = []
  y = []
  for line in lines: # e.g., TUR_001_004 1 9
    inline = line.split()
    utt = inline[0]
    y.append([int(i) for i in inline[1:]])

    utt_lst.append(utt)


  #Y = MultiLabelBinarizer().fit_transform(y)
  mlb = MultiLabelBinarizer()
  mlb.fit([(0,), (1,), (2,), (3,), (4,), (5,), (6,), (7,), (8,), (9,), (10,), (11,)])
  Y = mlb.transform(y)

  utt2label = {}
  for i in range(0, len(utt_lst)):
    utt = utt_lst[i]
    utt2label[utt] = Y[i]

  print "Y.shape:", Y.shape
  #np.set_printoptions(threshold=np.nan, suppress=True); print Y; sys.exit(0)
  #pprint.pprint(utt2label); sys.exit(0); 
  # --------------------------------------------------------
  # --------------------------------------------------------
  ngram_map = pickle.load(f_pkl)
  DIM = len(ngram_map)

  file_feats = open(f_feats, "r"); #DIM = 271141

  lines = file_feats.readlines()
  file_feats.close()

  utt2feats = {}

  for line in lines:
    inline = line.strip().split()

    utt = inline[0]
    if utt not in utt_lst:
      continue

    dic = {}
    for i in inline[1:]:
      t, tf = i.split(":")
      dic[int(t)] = float(tf)

    x = []
    for t in range(1, DIM + 1):
      x.append(dic.get(t, 0))

    utt2feats[utt] = x

  # --------------------------------------------------------

  utt_train_lst = utt_lst
  random.shuffle(utt_train_lst)

  Y_train = []
  X_train = []
  for utt in utt_train_lst:
    Y_train.append(utt2label[utt])
    X_train.append(utt2feats[utt])

  Y_train = np.asarray(Y_train)

  #np.set_printoptions(threshold=np.nan, suppress=True); pprint.pprint(len(utt2feats)); print utt2feats["CHN_DEV_081_023"]; sys.exit(0)
  # --------------------------------------------------------
  # --------------------------------------------------------
  file_feats_eval = open(f_feats, "r")

  lines = file_feats_eval.readlines()
  file_feats_eval.close()

  X_test = []
  utt_test_lst = []

  for line in lines:
    inline = line.strip().split()

    dic = {}
    for i in inline[1:]:
      t, tf = i.split(":")
      dic[int(t)] = float(tf)

    x = []
    for t in range(1, DIM + 1):
      x.append(dic.get(t, 0))

    X_test.append(x)

    utt_test_lst.append(inline[0])
  # --------------------------------------------------------
  transformer = TfidfTransformer(norm='l2', use_idf=True, smooth_idf=True)

  X_train = np.asarray(X_train)
  X_test = np.asarray(X_test)

  #transformer.fit(X_train + X_test)
  transformer.fit(X_train)

  X_train = transformer.transform(X_train)
  X_test = transformer.transform(X_test)

  with open(wdir + "/tfidfTransformer.pkl", 'wb') as wf:
    pickle.dump(transformer, wf)
  # --------------------------------------------------------
  #clf = SGDClassifier(loss='hinge', alpha=.001, n_iter=30, penalty='l2')
  clf = SGDClassifier(loss='hinge', alpha=.0001, n_iter=30, penalty='l2'); #print clf.get_params()

  classif = OneVsRestClassifier(clf)

  y_score = classif.fit(X_train, Y_train).decision_function(X_test)
  n_classes = Y_train.shape[1]

  with open(wdir + "/clf.pkl", 'wb') as wf:
    pickle.dump(classif, wf)
  # --------------------------------------------------------
  # Probability calibration
  #if True:
  if False:
    y_score = y_score[:, :-1] # ignore out-of-domain outputs !
    #y_score = (y_score - y_score.min()) / (y_score.max() - y_score.min())

    ## normalize scores
    s_min = copy.deepcopy(y_score.min())
    s_max = copy.deepcopy(y_score.max())
    for i in range(n_classes - 1):
      if y_score[:, i].max() - y_score[:, i].min() > 0.001:
        y_score[:, i] = (y_score[:, i] - s_min) / (s_max - s_min)
      else:
        print i, "y_score[:, i].max(), y_score[:, i].min():", y_score[:, i].max(), y_score[:, i].min()
    ##
    print "y_score:", y_score.shape, y_score.min(), y_score.max()


    # Write output
    wfile = file("system_output.json", "w")
    wfile.write("[\n")
    for i in range(len(utt_test_lst)):
      utt = utt_test_lst[i]
      for j in range(n_classes - 1): # do not output out-of-domain prob
        wfile.write("{\n")
        wfile.write("    \"DocumentID\": \"%s\",\n" % utt)
        wfile.write("    \"Type\": \"%s\",\n" % int2label[j])
        #wfile.write("    \"TypeConfidence\": %.2f\n" % y_score[i, j])
        wfile.write("    \"TypeConfidence\": %.4f\n" % y_score[i, j])

        if i == (len(utt_test_lst) - 1) and j == (n_classes - 2):
          wfile.write("}\n")
        else:
          wfile.write("},\n")

    wfile.write("]")
  # --------------------------------------------------------
  # Compute metrics on X_train
  average_precision = dict()
  y_score = classif.decision_function(X_train)
  for i in range(n_classes):
    average_precision[i] = average_precision_score(Y_train[:, i], y_score[:, i])

  average_precision["micro"] = average_precision_score(Y_train, y_score, average="micro")
  print "Training average precision:", average_precision
  print "\n" + str(datetime.now()) + "\n"
  print "--------------------------------------------------"
# ----------------------------------------------------------
# ----------------------------------------------------------
if __name__ == "__main__":
  main()


