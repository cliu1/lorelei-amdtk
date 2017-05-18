#!/usr/bin/env bash
# 
#

set -e
set -o pipefail

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
    $root/$model_type/unigram_labels_$decode/ \
    $root/data/decode.tra || exit 1;

  steps/trigram.py $root/data/decode.tra $root/data/ngram2dim.pkl \
    $root/data/decode.feats || exit 1;
fi

if [ ! -f $root/data/decode.json ]; then
  if [ ! -f $root/data/clf.pkl ]; then
    echo "expect" $root/data/clf.pkl && exit 1;
  fi

  steps/clf.py $root/data/decode.feats || exit 1;
fi

echo "Finished on" `date` && exit 0;

