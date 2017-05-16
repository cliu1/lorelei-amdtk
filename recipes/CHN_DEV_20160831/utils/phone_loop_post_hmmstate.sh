#!/usr/bin/env bash

#
# Generate the states posteriors from the infinite phone-loop
#

if [ $# -ne 1 ]; then
    echo "usage: $0 <setup.sh>"
    exit 1
fi

setup=$1
source $setup || exit 1

model="/export/a15/ws16londe/JHUWorkshop2016/AUD/tools/amdtk/recipes/timit/ploop_lmfcc_c1_T100_s3_g2_a3_b3/unigram/model.bin"
#model="$train_dir/iter$niter/model.bin"
#post_dir=`echo $fb_post_dir | sed -e s@fb_post@fb_post_ac_${ac_scale}@`

if [ ! -e "$post_dir"/.done ]; then

    # Create the output _directory.
    mkdir -p "$post_dir"

    # Generating the posteriors. Here we use the "HTK trick" as we want
    # to build HTK lattices from the posteriors.
    amdtk_run $parallel_profile \
        --ntasks "$parallel_n_core" \
        --options "$post_parallel_opts" \
        "pl-post"  \
        "$post_keys" \
        "amdtk_ploop_fb_post_ac_scale --hmm_states --ac_scale=${ac_scale} $model $post_fea_dir/\${ITEM1}.${fea_ext} \
        $fb_post_ac_dir/\${ITEM1}.htk" \
        "$fb_post_ac_dir" || exit 1

    date > "$fb_post_ac_dir"/.done
else
    echo "The posteriors have already been generated. Skipping."
fi

