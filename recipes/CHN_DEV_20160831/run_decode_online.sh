#!/usr/bin/env bash
# 
#

set -e -o pipefail

DocID=CHN_EVAL_001_001
audioFile=/export/corpora5/LORELEI/speech/LDC2016E115_LORELEI_Mandarin_Evaluation_Speech_Database/CHN_EVAL_20160831/CHN_EVAL_20160831/001/AUDIO/CHN_EVAL_001_001.flac

#
. ./lang.conf || exit 1;

#####################################################################
echo ---------------------------------------------------------------------
echo "Start bottleneck feature extraction on" `date`
echo ---------------------------------------------------------------------

root=$(pwd -P)
fea_dir_decode=${fea_dir_decode}_online
mkdir -p $fea_dir_decode
if [ ! -f $fea_dir_decode/${DocID}.fea ]; then

  pushd $kaldi_dir || exit 1;

  L=${decode}_online/$DocID
  data_dir=data/$L/data_conv && mkdir -p $data_dir || exit 1;
  if [ ! -f $data_dir/.done ]; then

    [ ! -f $audioFile ] && echo "No $audioFile" && exit 1;
    echo "$audioFile" > $data_dir/filelist.list

    ln -sf $root/steps/make_bn.sh .
    ln -sf $root/steps/make_pitch.sh steps/make_pitch.sh
    
    . ./path.sh
    . ./cmd.sh
    
    ./make_bn.sh $multidir $bnf_layer $L $data_dir
  fi
  
  data_dir_bnf=${data_dir}_bnf
  while read -r line; do
    utt=`echo $line | awk '{print $1}'`
    path=`echo $line | awk '{print $2}'`

    #echo $line > $root/$fea_dir_decode/${utt}".fea"
    echo "$utt $kaldi_dir/$path" > $root/$fea_dir_decode/${utt}".fea"
  done < $data_dir_bnf/feats_cmvn.scp

  popd
fi

#####################################################################
echo ---------------------------------------------------------------------
echo "Start AUD decoding on" `date`
echo ---------------------------------------------------------------------

setup=$root/setup_decode_online.sh
if [ ! -f $setup ]; then
  echo "expect" $setup && exit 1;
else
  source $setup
fi

[ ! -f $root/$model_type/unigram/.done ] && \
  echo "expect model in $root/$model_type/unigram/" && exit 1;

mkdir -p $root/data/${decode}_online_keys
label_keys=$root/data/${decode}_online_keys/${DocID}.keys
label_dir=$root/$model_type/unigram_labels_${decode}_online
if [ ! -f $label_dir/${DocID}.lab ]; then
  echo "Labeling"

  . $root/path.sh

  fea=$fea_dir/${DocID}.fea
  if [ ! -f $fea ]; then
    echo "expect $fea" && exit 1;
  else
    echo "using $fea"
  fi

  echo $DocID > $label_keys
   
  utils/phone_loop_label.sh $setup $root/$model_type/unigram \
      $label_dir $label_keys || exit 1;

  # removes the 'bin' directory of the environment activated with 'source activate' from PATH.
  source deactivate || exit 1;
fi

#####################################################################
echo ---------------------------------------------------------------------
echo "Start situation frame type classification on" `date`
echo ---------------------------------------------------------------------

outdir=$root/data/${decode}_online_outputs && mkdir -p $outdir
if [ ! -f $outdir/${DocID}.tra ]; then
  steps/label2tra.py $label_keys \
    $label_dir \
    $outdir/${DocID}.tra || exit 1;

  steps/trigram.py $outdir/${DocID}.tra $root/data/ngram2dim.pkl \
    $outdir/${DocID}.feats || exit 1;
fi

if [ ! -f $outdir/${DocID}.json ]; then
  if [ ! -f $root/data/clf.pkl ] || [ ! -f $root/data/tfidfTransformer.pkl ]; then
    echo "expect $root/data/clf.pkl and $root/data/tfidfTransformer.pkl" && exit 1;
  fi

  steps/clf.py $root/data $outdir/${DocID}.feats $outdir/${DocID}.json || exit 1;
fi

echo "Finished on" `date` && exit 0;

