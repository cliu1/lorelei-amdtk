#!/usr/bin/env bash
# 
#

set -e
set -o pipefail

. ./lang.conf || exit 1;

#####################################################################
echo ---------------------------------------------------------------------
echo "Start Acoustic Unit Discovery (AUD) training on" `date`
echo ---------------------------------------------------------------------

. `pwd -P`/path.sh || exit 1;

setup="`pwd -P`/setup.sh"
if [ ! -f $setup ]; then
  echo "expect" $setup && exit 1;
else
  source $setup || exit 1;
fi

mkdir -p $root/$model_type || exit 1;
if [ ! -f $root/$model_type/unigram/.done ]; then
  #echo "Data preparation..."
  #echo "Features extraction..."

  echo "Creating the model..."
  utils/phone_loop_create.sh $setup $root/$model_type/initial_model || exit 1
  echo done

  echo "Training the model with unigram LM..."
  utils/phone_loop_train.sh $setup 10 $root/$model_type/initial_model \
    $root/$model_type/unigram || exit 1
  echo "AUD training done on" `date`
fi

if [ ! -f $root/$model_type/unigram_labels/.done ]; then
  echo "Labeling the unigram model..."
  utils/phone_loop_label.sh $setup $root/$model_type/unigram \
      $root/$model_type/unigram_labels || exit 1
  echo "Labeling the training corpus done on" `date`
fi

# removes the 'bin' directory of the environment activated with 'source activate' from PATH.
source deactivate || exit 0;


#####################################################################
echo ---------------------------------------------------------------------
echo "Start situation frame type classifier training on" `date`
echo ---------------------------------------------------------------------

if [ ! -f $root/data/utt2label_shuf ]; then
  steps/annotation.py $root/data/lorelei_situation_frames.json \
    $root/data/utt2label || exit 1;

  shuf $root/data/utt2label > $root/data/utt2label_shuf || exit 1;
fi

if [ ! -f $root/data/train.tra ]; then
  steps/label2tra.py $root/data/train.keys \
    $root/$model_type/unigram_labels/ \
    $root/data/train.tra || exit 1;

  steps/trigram.py $root/data/train.tra $root/data/ngram2dim.pkl \
    $root/data/train.feats || exit 1;
fi

if [ ! -f $root/data/clf.pkl ]; then
  # expect $root/data/utt2label_shuf $root/data/ngram2dim.pkl
  steps/clf.py $root/data/train.feats || exit 1;
fi

echo "Finished on" `date` && exit 0;

