#
# This file defines all the configuration variables for a particular 
# experiment. Set the different paths according to your system. Most of the 
# values predefined here are generic and should yield decent results.
# However, they are most likely not optimal and need to be tuned for each 
# particular data set.
#

############################################################################
# Directories.                                                             #
############################################################################
root=$(pwd -P)  

############################################################################
# SGE settings.                                                            #
############################################################################

# Set your parallel environment. Supported environment are:
#   * local
#   * sge
#   * openccs.
#export AMDTK_PARALLEL_ENV="local"
export AMDTK_PARALLEL_ENV="sge"

parallel_n_core=100
parallel_profile="--profile $root/path.sh"

## SGE - CLSP ## 
queues="all.q"

############################################################################
# Features settings.                                                       #
############################################################################
. lang.conf

fea_ext='fea'
#fea_type=mfcc
fea_type=bn
fea_dir=$fea_dir_train

############################################################################
# Model settings.                                                          #
############################################################################
#concentration=1
concentration=10
truncation=200
eta=3
nstates=3
alpha=3
ncomponents=2
kappa=5
a=3
b=3
model_type=ploop_l${fea_type}_c${concentration}_T${truncation}_s${nstates}_g${ncomponents}_a${a}_b${b}

############################################################################
# Training settings.                                                       #
############################################################################
train_keys=$root/data/train.keys
train_niter=10

## SGE - CLSP ## 
train_parallel_opts="-q $queues -l arch=*64"

############################################################################
# Language model training.                                                 #
############################################################################
lm_params=".5,1:.5,1"
lm_train_niter=5
lm_weight=1
ac_weight=1

############################################################################
# Posteriors settings.                                                     #
############################################################################
post_keys=$root/data/train.keys

## SGE - CLSP ## 
post_sge_res="-q $queues -l arch=*64"

############################################################################
# Lattices and counts generation.                                          #
############################################################################
beam_thresh=0.0
penalty=-1
gscale=1
latt_count_order=3
sfx=bt${beam_thresh}_p${penalty}_gs${gscale}
conf_latt_dir=${root}/${model_type}/conf_lattices

## SGE - CLSP ## 
latt_parallel_opts="-q $queues -l arch=*64"

############################################################################
# Labeling settings.                                                       #
############################################################################
label_keys=$root/data/train.keys

## SGE - CLSP ## 
label_parallel_opts="-q $queues -l arch=*64"

############################################################################
# Scoring settings.                                                        #
############################################################################
#score_keys=$root/data/train.keys
#score_ref=$root/data/score.ref
