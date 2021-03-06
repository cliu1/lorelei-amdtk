#!/usr/bin/env bash
# 
#

set -e -o pipefail

. ./lang.conf || exit 1;

#####################################################################
echo ---------------------------------------------------------------------
echo "Start bottleneck feature extraction on" `date`
echo ---------------------------------------------------------------------

root=$(pwd -P)
mkdir -p $fea_dir_decode
if [ ! -f $fea_dir_decode/.done ]; then

  pushd $kaldi_dir || exit 1;

  data_dir=data/$decode/data_conv && mkdir -p $data_dir || exit 1;
  if [ ! -f $data_dir/.done ]; then

    [ -z $corpus ] && echo "No corpus" && exit 1;
    find -L $corpus  -name "*flac" > $data_dir/filelist.list

    ln -sf $root/steps/make_bn.sh .
    ln -sf $root/steps/make_pitch.sh steps/make_pitch.sh
    
    . ./path.sh
    . ./cmd.sh
    
    ./make_bn.sh $multidir $bnf_layer $decode $data_dir
  fi
  
  data_dir_bnf=${data_dir}_bnf
  while read -r line; do
    utt=`echo $line | awk '{print $1}'`
    path=`echo $line | awk '{print $2}'`

    #echo $line > $root/$fea_dir_decode/${utt}".fea"
    echo "$utt $kaldi_dir/$path" > $root/$fea_dir_decode/${utt}".fea"
  done < $data_dir_bnf/feats_cmvn.scp
  touch $root/$fea_dir_decode/.done

  popd
fi

#####################################################################
echo ---------------------------------------------------------------------
echo "Start AUD decoding on" `date`
echo ---------------------------------------------------------------------


setup=$root/setup_decode.sh
if [ ! -f $setup ]; then
  echo "expect" $setup && exit 1;
else
  source $setup
fi

[ ! -f $root/$model_type/unigram/.done ] && \
  echo "expect model in $root/$model_type/unigram/" && exit 1;

if [ ! -f $root/$model_type/unigram_labels_$decode/.done ]; then
  echo "Labeling" $decode

  . $root/path.sh

  if [ ! -f $fea_dir/.done ]; then
    echo "expect $fea_dir/*.fea" && exit 1;
  else
    echo "using fea_dir: ./$fea_dir"
  fi

  utils/phone_loop_label.sh $setup $root/$model_type/unigram \
      $root/$model_type/unigram_labels_$decode || exit 1;

  # removes the 'bin' directory of the environment activated with 'source activate' from PATH.
  source deactivate || exit 1;
fi

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

