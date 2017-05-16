#!/usr/bin/env bash

#
# Do forward-backward alogrithm on latt
#


#while [[ $# >2 ]]
#do
#	key=$1
#	case $key in
#		--map)
#			mapfile="$2"
#			;;
#		*)
#			;;
#	esac
#	shift
#	shift
#done
#

if [ $# -ne 3 ];then
   echo "usaage: $0  <setup.sh> *.map <outdir>"
   exit 1
fi

setup=$1
mapfile=$2
outdir=$3

source $setup || exit 1


if [ ! -e "$outdir"/.done ]; then
	mkdir -p "$outdir"
	
        amdtk_run $parallel_profile \
        --ntasks "$parallel_n_core" \
        --options "$post_parallel_opts" \
        "kaldi-1best"  \
	"$post_keys" \
	"amdtk_label_to_kaldi_1best $mapfile $label_dir_train/\${ITEM1}.lab  \
		$outdir/\${ITEM1}.post $mfcc_fea_dir"  \
                "$outdir" || exit 1
	date > "$outdir"/.done
else
	echo "The kaldi 1best posts have already been converted to kaldi format. Skipping ....."
fi

