#!/usr/bin/python
#
#
#

import sys, os.path
import random, copy, pickle, pprint
from datetime import datetime

import numpy as np

from sklearn.preprocessing import MultiLabelBinarizer
from sklearn.feature_extraction.text import TfidfTransformer 
from sklearn.linear_model import SGDClassifier
from sklearn.multiclass import OneVsRestClassifier
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
## ----------------------------------------------------------
## ----------------------------------------------------------
## main
## ----------------------------------------------------------
## ----------------------------------------------------------
def main():
  srcdir = sys.argv[1]
  f_feats = sys.argv[2]

  f_utt2label = srcdir + "/utt2label"
  f_dic = srcdir + "/ngram2dim.pkl"
  f_clf = srcdir + "/clf.pkl"
  # --------------------------------------------------------
  # --------------------------------------------------------
  print "read", f_dic
  with open(f_dic, 'rb') as f:
    ngram_map = pickle.load(f)
    DIM = len(ngram_map)
    print "DIM:", DIM

  utt_lst = []
  utt2feats = {}
  print "read", f_feats
  with open(f_feats, "r") as f:
    for line in f:
      inline = line.strip().split()

      utt = inline[0]
      utt_lst.append(utt)

      dic = {}
      for i in inline[1:]:
        t, tf = i.split(":")
        dic[int(t)] = float(tf)

      x = []
      for t in range(1, DIM + 1):
        x.append(dic.get(t, 0))

      utt2feats[utt] = x

  #np.set_printoptions(threshold=np.nan, suppress=True); pprint.pprint(len(utt2feats)); sys.exit(0)
  # --------------------------------------------------------
  # --------------------------------------------------------
  ## train
  if os.path.isfile(f_clf) == False:

    mlb = MultiLabelBinarizer()
    mlb.fit([[int(i) for i in range(0, len(int2label))]])

    utt2label = {}
    print "read", f_utt2label
    with open(f_utt2label, "r") as f:
      for line in f:  # e.g., TUR_001_004 1 9
        inline = line.split()
        utt = inline[0]
        utt2label[utt] = mlb.transform([[int(i) for i in inline[1:]]]).flatten()

    #pprint.pprint(utt2label); sys.exit(0);
    # --------------------------------------------------------
    # --------------------------------------------------------
    utt2label_lst = utt2label.keys()
    random.shuffle(utt2label_lst)

    Y = []
    X = []
    for utt in utt2label_lst:
      Y.append(utt2label[utt])
      X.append(utt2feats[utt])

    Y = np.asarray(Y)
    X = np.asarray(X)

    print "Training: Y.shape", Y.shape, "; X.shape", X.shape

    transformer = TfidfTransformer(norm='l2', use_idf=True, smooth_idf=True)
    transformer.fit(X) #transformer.fit(X_train + X_test)
    X = transformer.transform(X)

    #clf = SGDClassifier(loss='hinge', alpha=.001, n_iter=30, penalty='l2')
    clf = SGDClassifier(loss='hinge', alpha=.0001, n_iter=30, penalty='l2')
    print clf.get_params()

    classif = OneVsRestClassifier(clf)
    y_score = classif.fit(X, Y).decision_function(X)

    # Compute metrics after training
    average_precision = dict()
    for i in range(len(int2label)):
      average_precision[i] = average_precision_score(Y[:, i], y_score[:, i])

    average_precision["micro"] = average_precision_score(Y, y_score, average="micro")
    print "Average precision on train:", average_precision

    with open(srcdir + "/tfidfTransformer.pkl", 'wb') as wf:
      pickle.dump(transformer, wf)

    with open(srcdir + "/clf.pkl", 'wb') as wf:
      pickle.dump(classif, wf)
  # --------------------------------------------------------
  # --------------------------------------------------------
  # --------------------------------------------------------
  ## decode
  else:
    with open(srcdir + "/tfidfTransformer.pkl", 'rb') as f:
      transformer = pickle.load(f)

    with open(srcdir + "/clf.pkl", 'rb') as f:
      classif = pickle.load(f)

    X = []
    for utt in utt_lst:
      X.append(utt2feats[utt])

    X = transformer.transform(X)

    y_score = classif.decision_function(X)
    n_classes = len(int2label)

    ## Probability calibration / normalize scores
    #y_score = (y_score - y_score.min()) / (y_score.max() - y_score.min())
    y_score = y_score[:, :-1] # ignore out-of-domain outputs !

    s_min = copy.deepcopy(y_score.min())
    s_max = copy.deepcopy(y_score.max())
    for i in range(n_classes - 1):
      if y_score[:, i].max() - y_score[:, i].min() > 0.001:
        y_score[:, i] = (y_score[:, i] - s_min) / (s_max - s_min)
      else:
        print i, "y_score[:, i].max(), y_score[:, i].min():", y_score[:, i].max(), y_score[:, i].min()

    print "y_score:", y_score.shape, y_score.min(), y_score.max()

    ## Write output
    wfile = file(srcdir + "/decode.json", "w")
    wfile.write("[\n")
    for i in range(len(utt_lst)):
      utt = utt_lst[i]
      for j in range(n_classes - 1): # do not output out-of-domain prob
        wfile.write("{\n")
        wfile.write("    \"DocumentID\": \"%s\",\n" % utt)
        wfile.write("    \"Type\": \"%s\",\n" % int2label[j])
        #wfile.write("    \"TypeConfidence\": %.2f\n" % y_score[i, j])
        wfile.write("    \"TypeConfidence\": %.4f\n" % y_score[i, j])

        if i == (len(utt_lst) - 1) and j == (n_classes - 2):
          wfile.write("}\n")
        else:
          wfile.write("},\n")

    wfile.write("]")
  # --------------------------------------------------------
  # --------------------------------------------------------
  print str(datetime.now())
## ----------------------------------------------------------
## ----------------------------------------------------------
if __name__ == "__main__":
  main()


