#!/usr/bin/env bash
# 
#

set -e
set -o pipefail

#####################################################################
echo ---------------------------------------------------------------------
echo "Start bottleneck feature extraction on" `date`
echo ---------------------------------------------------------------------

if [ ! -f $fea_dir/.done ]; then
  pushd $kaldi_dir || exit 1;



  set -o nounset
  
  . ./path.sh
  . ./cmd.sh
  
  #input_data=/export/b04/cliu1/kaldi-multilingual-pegahgh/egs/multi_en/multi-g-ivec-2/data/CHN_DEV_20160831/test_conv_hires_mfcc_pitch
  output_data=./test_conv_bnf
  train_nj=32
  bnf_layer=5
  
  utils/copy_data_dir.sh $input_data $output_data
  steps/nnet3/make_bottleneck_features.sh --use-gpu true --nj $train_nj --cmd "$train_cmd" \
    renorm${bnf_layer} $input_data $output_data $extractor || exit 1;  

  popd
fi


#####################################################################
echo ---------------------------------------------------------------------
echo "Start AUD decoding on" `date`
echo ---------------------------------------------------------------------

. ./lang.conf || exit 1;

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

