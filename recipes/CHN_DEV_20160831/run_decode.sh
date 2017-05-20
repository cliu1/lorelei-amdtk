#!/usr/bin/env bash
# 
#

set -e -o pipefail
set -u
set -o nounset


. ./lang.conf || exit 1;

#####################################################################
echo ---------------------------------------------------------------------
echo "Start bottleneck feature extraction on" `date`
echo ---------------------------------------------------------------------

if [ ! -f $fea_dir/.done ]; then
  root=$(pwd -P)

  pushd $kaldi_dir || exit 1;

  [ ! -f steps/make_bn.sh ] && ln -s $root/steps/make_bn.sh . || exit 1;
  [ ! -f steps/make_pitch.sh ] && ln -s $root/steps/make_pitch.sh steps/make_pitch.sh || exit 1;

  . ./path.sh
  . ./cmd.sh
  
  ./make_bn.sh $multidir $bnf_layer $decode || exit 1;

  bnf_data_dir=data/$decode/data_conv_bnf
  mkdir -p $bnf_data_dir/feats4aud  || exit 1;
  
  while read -r line; do
    utt=`echo $line | awk '{print $1}'`
    echo $line > $bnf_data_dir/feats4aud/${utt}".fea"
  done < $bnf_data_dir/feats_cmvn.scp

  popd
fi


#####################################################################
echo ---------------------------------------------------------------------
echo "Start AUD decoding on" `date`
echo ---------------------------------------------------------------------

. `pwd -P`/path.sh || exit 1;

setup="`pwd -P`/setup_decode.sh"
if [ ! -f $setup ]; then
  echo "expect" $setup && exit 1;
else
  source $setup || exit 1;
fi

if [ ! -f $root/$model_type/unigram/.done ]; then
  echo "expect model in $root/$model_type/unigram/" && exit 1;
fi

if [ ! -f $root/$model_type/unigram_labels_$decode/.done ]; then
  echo "Labeling" $decode

  utils/phone_loop_label.sh $setup $root/$model_type/unigram \
      $root/$model_type/unigram_labels_$decode || exit 1
fi

# removes the 'bin' directory of the environment activated with 'source activate' from PATH.
source deactivate || exit 0;


#####################################################################
echo ---------------------------------------------------------------------
echo "Start situation frame type classification on" `date`
echo ---------------------------------------------------------------------

if [ ! -f $root/data/decode.tra ]; then
  steps/label2tra.py $root/data/${decode}.keys \
    $root/$model_type/unigram_labels_$decode \
    $root/data/decode.tra || exit 1;

  steps/trigram.py $root/data/decode.tra $root/data/ngram2dim.pkl \
    $root/data/decode.feats || exit 1;
fi

if [ ! -f $root/data/decode.json ]; then
  if [ ! -f $root/data/clf.pkl ] || [ ! -f $root/data/tfidfTransformer.pkl ]; then
    echo "expect $root/data/clf.pkl and $root/data/tfidfTransformer.pkl" && exit 1;
  fi

  steps/clf.py $root/data $root/data/decode.feats || exit 1;
fi

echo "Finished on" `date` && exit 0;

