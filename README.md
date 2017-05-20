# lorelei-amdtk

The AMDTK (Acoustic Model Discovery ToolKit) is originally forked from https://github.com/iondel/amdtk, with changes for compatibility with kaldi, like reading kaldi features. Adapted from /export/b04/cliu1/AMDTK-0 on CLSP grid (e.g., ./install.sh -p /home/cliu1/anaconda3).

Add scripts for lorelei situation frame type classification based on scikit-learn.


# Things need to be copied for online decoding / Docker image:

dir=/export/b04/cliu1/lorelei-amdtk/recipes

for recipe in CHN_DEV_20160831 IL3_DEV_20160831; do
  cp $dir/$recipe/ploop_lbn_c10_T200_s3_g2_a3_b3/unigram/model.bin recipes/$recipe/ploop_lbn_c10_T200_s3_g2_a3_b3/unigram/

  cp $dir/$recipe/data/{ngram2dim.pkl,tfidfTransformer.pkl,clf.pkl} recipes/$recipe/data/
done

