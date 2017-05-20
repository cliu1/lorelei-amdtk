# lorelei-amdtk

1. The AMDTK (Acoustic Model Discovery ToolKit) is originally forked from https://github.com/iondel/amdtk, with changes for compatibility with kaldi, like reading kaldi features.

Adapted from /export/b04/cliu1/AMDTK-0 on CLSP grid (e.g., ./install.sh -p /home/cliu1/anaconda3).

2. Add scripts for lorelei situation frame type classification based on scikit-learn.


Things need to be copied to do online decoding:

ploop_lbn_c10_T200_s3_g2_a3_b3/unigram/model.bin 

data/ngram2dim.pkl
data/tfidfTransformer.pkl 
data/clf.pkl

