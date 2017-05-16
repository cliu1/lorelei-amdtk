#!/usr/bin/env bash

#
# Generate the states posteriors from the infinite phone-loop
#

#if [ $# -ne 3 ]; then
if [ $# -ne 4 ]; then
    #$echo "usage: $0 <setup.sh> <model_dir> <out_dir>"
    $echo "usage: $0 <setup.sh> <model_dir> <out_dir> <keys>"
    exit 1
fi

setup=$1
model=$2/model.bin
out_dir=$3

keys="$4"

source $setup || exit 1

source path.sh || exit 1

if [ ! -e "$out_dir"/.done ]; then

    # Create the output _directory.
    mkdir -p "$out_dir"

    # Generating the posteriors. Here we use the "HTK trick" as we want
    # to build HTK lattices from the posteriors.
    amdtk_run $parallel_profile \
        --ntasks "$parallel_n_core" \
        --options "$post_parallel_opts" \
        "pl-post"  \
        "$post_keys" \
        "amdtk_ploop_fb_post_ac_scale_kaldi --hmm_states --ac_scale=${ac_scale} $model $post_fea_dir/\${ITEM1}.${fea_ext} \
        $out_dir/\${ITEM1}.ark \${ITEM1}" \
        "$out_dir" || exit 1

        #"amdtk_ploop_fb_post_ac_scale --hmm_states --ac_scale=${ac_scale} $model $post_fea_dir/\${ITEM1}.${fea_ext} \
        #$out_dir/\${ITEM1}.htk" \
    date > "$out_dir"/.done
else
    echo "The posteriors have already been generated. Skipping."
fi

