#!/bin/bash
#
#

set -e -o pipefail

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;

use_pitch=true
use_entropy=false
use_ivector=false
use_bnf=true

pitch_conf=conf/pitch.conf
aux_suffix=

corpus=

train_nj=32

trap "echo Exited!; exit;" SIGINT SIGTERM
set -o errtrace
set -u

[ ! -f steps/make_pitch.sh ] && echo "No steps/make_pitch.sh" && exit 1;


####
if [ $# -ne 4 ]; then
    echo "Usage: $(basename $0) <multidir> <bnf_layer> <L> <dataset_dir>"
    #echo " e.g.: $(basename $0)"
    exit 1
fi

multidir=$1
bnf_layer=$2
L=$3
dataset_dir=$4  ## dataset_dir=data/$L/data_conv && mkdir -p $dataset_dir
#####################################################################
#
# Audio data directory preparation
#
#####################################################################
if [ ! -f  $dataset_dir/.done ] ; then
  echo ---------------------------------------------------------------------
  echo "Preparing data files in ${dataset_dir} on" `date`
  echo ---------------------------------------------------------------------

  for flac in `cat $dataset_dir/filelist.list `; do
    fx=`basename $flac`;
    fx=${fx%%.flac};
    #echo "$fx sox $flac -t wav -r 8000 -c 1 - sinc 60-3300 -t 30|"
    echo "$fx sox $flac -t wav -r 8000 -c 1 - sinc 300-3300 -t 100|"
  done > $dataset_dir/wav.scp
  
  wav-to-duration scp:$dataset_dir/wav.scp  ark,t:- 2>$dataset_dir/wav-to-duration.log| \
    awk '{print $1, $1, 0.0, $2}' > $dataset_dir/segments
  
  for segment in `cat $dataset_dir/wav.scp | cut -f 1 -d ' ' `; do
    echo $segment $segment
  done > $dataset_dir/utt2spk
  
  utils/fix_data_dir.sh $dataset_dir

  touch $dataset_dir/.done
fi

if [ ! -f ${dataset_dir}_hires/.mfcc.done ]; then
    dataset=$(basename $dataset_dir)
    echo ---------------------------------------------------------------------
    echo "Preparing MFCC features in  ${dataset_dir}_hires on" `date`
    echo ---------------------------------------------------------------------
    utils/copy_data_dir.sh $dataset_dir ${dataset_dir}_hires

    mfccdir=mfcc_hires/$L
    steps/make_mfcc.sh --nj $train_nj --mfcc-config conf/mfcc_hires.conf \
        --cmd "$train_cmd" ${dataset_dir}_hires exp/$L/make_hires/$dataset $mfccdir;
    steps/compute_cmvn_stats.sh ${dataset_dir}_hires exp/$L/make_hires/${dataset} $mfccdir;
    utils/fix_data_dir.sh ${dataset_dir}_hires;

    touch ${dataset_dir}_hires/.mfcc.done
fi

echo use_pitch = $use_pitch and use_entropy = $use_entropy  and use_bnf = $use_bnf
if [[ "$use_pitch" == "true" || "$use_entropy" == "true" ]]; then
  dataset=$(basename $dataset_dir)
  echo use_pitch = $use_pitch
  echo use_entropy = $use_entropy
  pitchdir=pitch/$L
  entropydir=entropy/$L
  if $use_pitch; then
    if [ ! -f ${dataset_dir}_pitch/.done ]; then
      utils/copy_data_dir.sh ${dataset_dir} ${dataset_dir}_pitch
      steps/make_pitch.sh --nj 70 --pitch-config $pitch_conf \
        --cmd "$train_cmd" ${dataset_dir}_pitch exp/$L/make_pitch/${dataset} $pitchdir;
      touch ${dataset_dir}_pitch/.done
    fi
    aux_suffix=${aux_suffix}_pitch
  fi

  if $use_entropy; then
    if [ ! -f ${dataset_dir}_entropy/.done ]; then
      utils/copy_data_dir.sh ${dataset_dir} ${dataset_dir}_entropy
      steps/make_voicing_subband_pitch.sh --nj 70 --voicing-config $voicing_conf \
        --cmd "$train_cmd" ${dataset_dir}_entropy exp/$L/make_entropy/${dataset} $entropydir;
      touch ${dataset_dir}_entropy/.done
    fi
    aux_suffix=${aux_suffix}_entropy
  fi

  if $use_pitch && $use_entropy; then
    if [ ! -f ${dataset_dir}_pitch_entropy/.done ]; then
      steps/append_feats.sh --nj 16 --cmd "$train_cmd" ${dataset_dir}_pitch \
        ${dataset_dir}_entropy ${dataset_dir}_pitch_entropy \
        exp/$L/append_entropy_pitch/${dataset} entropy_pitch/$L
      touch ${dataset_dir}_pitch_entropy/.done
    fi
    aux_suffix=${aux_suffix}_pitch_entropy
  fi
  
  if [ ! -f ${dataset_dir}_hires_mfcc${aux_suffix}/.done ]; then
    steps/append_feats.sh --nj 16 --cmd "$train_cmd" ${dataset_dir}_hires \
      ${dataset_dir}${aux_suffix} ${dataset_dir}_hires_mfcc${aux_suffix} \
      exp/$L/append_mfcc${aux_suffix}/${dataset} mfcc_hires${aux_suffix}/$L
 
    steps/compute_cmvn_stats.sh ${dataset_dir}_hires_mfcc${aux_suffix} \
      exp/$L/make_cmvn_mfcc${aux_suffix}/${dataset} mfcc_hires${aux_suffix}/$L

    touch ${dataset_dir}_hires_mfcc${aux_suffix}/.done
  fi
fi

dataset=$(basename $dataset_dir)
bnf_data_dir=${dataset_dir}_bnf
if [[ $use_bnf && ! -f $bnf_data_dir/.done ]]; then

  echo "Preparing BN features in ${bnf_data_dir} on" `date`

  steps/nnet3/make_bottleneck_features.sh --use-gpu true --nj $train_nj --cmd "$train_cmd" \
    renorm${bnf_layer} \
    ${dataset_dir}_hires_mfcc${aux_suffix} $bnf_data_dir $multidir || exit 1; 

  copy-feats scp:$bnf_data_dir/feats.scp ark:- | apply-cmvn --norm-means=true --norm-vars=true \
    --utt2spk=ark:$bnf_data_dir/utt2spk scp:$bnf_data_dir/cmvn.scp ark:- \
    ark,scp:$bnf_data_dir/feats_cmvn.ark,$bnf_data_dir/feats_cmvn.scp

  touch $bnf_data_dir/.done
fi

echo ---------------------------------------------------------------------
echo "Done on" `date`
echo ---------------------------------------------------------------------

