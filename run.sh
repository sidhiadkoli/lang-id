#!/bin/bash
#
# Based mostly on the Switchboard recipe. The training database is TED-LIUM,
# it consists of TED talks with cleaned automatic transcripts:
#
# http://www-lium.univ-lemans.fr/en/content/ted-lium-corpus
# http://www.openslr.org/resources (Mirror).
#
# The data is distributed under 'Creative Commons BY-NC-ND 3.0' license,
# which allow free non-commercial use, while only a citation is required.
#
# Copyright  2014  Nickolay V. Shmyrev
#            2014  Brno University of Technology (Author: Karel Vesely)
#            2016  Vincent Nguyen
#            2016  Johns Hopkins University (Author: Daniel Povey)
#
# Apache 2.0
# Modified by Sidhi Adkoli for language identification project (COMS 6998).

. ./cmd.sh
. ./path.sh


echoerr() { echo "$@" 1>&2; }
set -e -o pipefail -u

nj=8
decode_nj=4    
stage=0

. utils/parse_options.sh # accept options

# Data preparation
if [ $stage -le 0 ]; then
  if [ ! -d "db/sa3505_data" ] ; then
    unzip -q db/sa3505_data.zip -d db/
  fi
fi

echo "6998:Completed stage: 0..."
echoerr "6998:Completed stage: 0..."
# Prepare each of the language data and combine them into a single directory.
if [ $stage -le 1 ]; then
  local/prepare_data.sh
fi

echo "6998:Completed stage: 1..."
echoerr "6998:Completed stage: 1..."
# Prepare the data dictionary.
if [ $stage -le 2 ]; then
  local/prepare_dict.sh
fi

echo "6998:Completed stage: 2..."
echoerr "6998:Completed stage: 2..."
# Prepare language-related files.
if [ $stage -le 3 ]; then
   utils/prepare_lang.sh data/local/dict_nosp \
      "<unk>" data/local/lang_nosp data/lang_nosp
fi

echo "6998:Completed stage: 3..."
echoerr "6998:Completed stage: 3..."
# Train the language model (order 4).
if [ $stage -le 4 ]; then
    local/ted_train_lm.sh 4
fi

echo "6998:Completed stage: 4..."
echoerr "6998:Completed stage: 4..."
# Format language model.
if [ $stage -le 5 ]; then
    local/format_lms.sh 4
fi

echo "6998:Completed stage: 5..."
echoerr "6998:Completed stage: 5..."
# Feature extraction
if [ $stage -le 6 ]; then
  for set in test dev train; do
    dir=data/$set
    steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" $dir
    utils/fix_data_dir.sh $dir
    steps/compute_cmvn_stats.sh $dir
  done
fi

echo "6998:Completed stage: 6..."
echoerr "6998:Completed stage: 6..."
# Now we have 168 hours of training data.
# We'll create a subset with 10k short segments to make flat-start training easier:
if [ $stage -le 7 ]; then
  utils/subset_data_dir.sh data/train 10000 data/train_10kshort
  utils/data/remove_dup_utts.sh 10 data/train_10kshort data/train_10kshort_nodup
fi

echo "6998:Completed stage: 7..."
echoerr "6998:Completed stage: 7..."
# Train monophones.
if [ $stage -le 8 ]; then
  steps/train_mono.sh --nj $nj --cmd "$train_cmd" \
    data/train_10kshort_nodup data/lang_nosp exp/mono
fi

echo "6998:Completed stage: 8..."
echoerr "6998:Completed stage: 8..."
if [ $stage -le 9 ]; then
  steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    data/train data/lang_nosp exp/mono exp/mono_ali
  steps/train_deltas.sh --cmd "$train_cmd" \
    2500 30000 data/train data/lang_nosp exp/mono_ali exp/tri1
fi

echo "6998:Completed stage: 9..."
echoerr "6998:Completed stage: 9..."
if [ $stage -le 10 ]; then
  utils/mkgraph.sh data/lang_nosp exp/tri1 exp/tri1/graph_nosp

  #for dset in dev test; do
  #  steps/decode.sh --nj $decode_nj --cmd "$decode_cmd"  --num-threads 4 \
  #    exp/tri1/graph_nosp data/${dset} exp/tri1/decode_nosp_${dset}
  #done
fi

echo "6998:Completed stage: 10..."
echoerr "6998:Completed stage: 10..."
if [ $stage -le 11 ]; then
  steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    data/train data/lang_nosp exp/tri1 exp/tri1_ali

  steps/train_lda_mllt.sh --cmd "$train_cmd" \
    4000 50000 data/train data/lang_nosp exp/tri1_ali exp/tri2
fi

echo "6998:Completed stage: 11..."
echoerr "6998:Completed stage: 11..."
if [ $stage -le 12 ]; then
  utils/mkgraph.sh data/lang_nosp exp/tri2 exp/tri2/graph_nosp
  
  #for dset in dev test; do
  #  steps/decode.sh --nj $decode_nj --cmd "$decode_cmd"  --num-threads 4 \
  #    exp/tri2/graph_nosp data/${dset} exp/tri2/decode_nosp_${dset}
  #done
fi

echo "6998:Completed stage: 12..."
echoerr "6998:Completed stage: 12..."
if [ $stage -le 13 ]; then
  steps/get_prons.sh --cmd "$train_cmd" data/train data/lang_nosp exp/tri2
  utils/dict_dir_add_pronprobs.sh --max-normalize true \
    data/local/dict_nosp exp/tri2/pron_counts_nowb.txt \
    exp/tri2/sil_counts_nowb.txt \
    exp/tri2/pron_bigram_counts_nowb.txt data/local/dict
fi

echo "6998:Completed stage: 13..."
echoerr "6998:Completed stage: 13..."
if [ $stage -le 14 ]; then
  utils/prepare_lang.sh data/local/dict "<unk>" data/local/lang data/lang
  cp -rT data/lang data/lang_rescore
  cp data/lang_nosp/G.fst data/lang/
  cp data/lang_nosp_rescore/G.carpa data/lang_rescore/

  utils/mkgraph.sh data/lang exp/tri2 exp/tri2/graph

  #for dset in dev test; do
  #  steps/decode.sh --nj $decode_nj --cmd "$decode_cmd"  --num-threads 4 \
  #    exp/tri2/graph data/${dset} exp/tri2/decode_${dset}
  #done
fi

echo "6998:Completed stage: 14..."
echoerr "6998:Completed stage: 14..."
if [ $stage -le 15 ]; then
  steps/align_si.sh --nj $nj --cmd "$train_cmd" \
    data/train data/lang exp/tri2 exp/tri2_ali

  steps/train_sat.sh --cmd "$train_cmd" \
    5000 100000 data/train data/lang exp/tri2_ali exp/tri3

  utils/mkgraph.sh data/lang exp/tri3 exp/tri3/graph

  for dset in dev test; do
    steps/decode_fmllr.sh --nj $decode_nj --cmd "$decode_cmd"  --num-threads 4 \
      exp/tri3/graph data/${dset} exp/tri3/decode_${dset}
  done
fi

# the following shows you how to insert a phone language model in place of <unk>
# and decode with that.
# local/run_unk_model.sh

echo "6998:Completed stage: 15..."
echoerr "6998:Completed stage: 15..."
if [ $stage -le 16 ]; then
  # this does some data-cleaning.  It actually degrades the GMM-level results
  # slightly, but the cleaned data should be useful when we add the neural net and chain
  # systems.  If not we'll remove this stage.
  local/run_cleanup_segmentation.sh
fi


echo "6998:Completed stage: 16..."
echoerr "6998:Completed stage: 16..."
if [ $stage -le 17 ]; then
  local/chain/run_tdnn.sh --stage 20
fi

echo "$0: success."
exit 0
