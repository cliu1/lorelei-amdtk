#!/usr/bin/python
#
#
#

import sys, os, pprint
import random
from datetime import datetime


# ----------------------------------------------------------
# main
# ----------------------------------------------------------
def main():

  label2int = {"Civil Unrest or Wide-spread Crime" : 0,
    "Civil Unrest or Widespread Crime" : 0,
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
    "out-of-domain" : 11,
    "NONE OF THE ABOVE" : 11}

  #pprint.pprint(label2int); #sys.exit(0)
  # --------------------------------------------------------
  # --------------------------------------------------------
  f_label = sys.argv[1]
  wf_utt2label = sys.argv[2]

  file_label = open(f_label, "r")
  lines = file_label.readlines()
  file_label.close()

  utt_lst = []
  utt2label = {}
  for i in range(len(lines)):
    line = lines[i]
    if "DocumentID" not in line:
      continue

    utt = line.split("\"")[3]
    if utt not in utt_lst:
      utt_lst.append(utt)

    line = lines[i + 1]
    label = line.split("\"")[3]

    if utt not in utt2label:
      utt2label[utt] = []

    utt2label[utt].append(label)

  #pprint.pprint(utt2label); sys.exit(0)
  # --------------------------------------------------------
  # write out
  with open(wf_utt2label, "w") as wfile:
    for utt in utt_lst:
      if utt not in utt2label:
        print "unexpected in line 66"
        #sys.exit(0)

      label = utt2label[utt]
      label = sorted([int(label2int[i]) for i in label])

      wfile.write(utt + " " + " ".join([str(i) for i in label]) + "\n")

  #print str(datetime.now())
# ----------------------------------------------------------
if __name__ == "__main__":
  main()


