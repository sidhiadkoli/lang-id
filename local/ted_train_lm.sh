#!/bin/bash

# Copyright 2016  Vincent Nguyen
#           2016  Johns Hopkins University (author: Daniel Povey)
# Apache 2.0
#
# This script trains a LM on the Cantab-Tedlium text data and tedlium acoustic training data.
# It is based on the example scripts distributed with PocoLM

# It will first check if pocolm is installed and if not will process with installation
# It will then get the source data from the pre-downloaded Cantab-Tedlium files
# and the pre-prepared data/train text source.


set -e
stage=0

echo "$0 $@"  # Print the command line for logging
. utils/parse_options.sh || exit 1;

dir=data/local/local_lm
sdir=data/
lm_dir=${dir}/data
order=$1

mkdir -p $dir
. ./path.sh || exit 1; # for KALDI_ROOT
export PATH=$KALDI_ROOT/tools/pocolm/scripts:$PATH
( # First make sure the pocolm toolkit is installed.
 cd $KALDI_ROOT/tools || exit 1;
 if [ -d pocolm ]; then
   echo Not installing the pocolm toolkit since it is already there.
 else
   echo "$0: Please install the PocoLM toolkit with: "
   echo " cd ../../../tools; extras/install_pocolm.sh; cd -"
   exit 1;
 fi
) || exit 1;

num_dev_sentences=10000

#bypass_metaparam_optim_opt=
# If you want to bypass the metaparameter optimization steps with specific metaparameters
# un-comment the following line, and change the numbers to some appropriate values.
# You can find the values from output log of train_lm.py.
# These example numbers of metaparameters is for 4-gram model (with min-counts)
# running with train_lm.py.
# The dev perplexity should be close to the non-bypassed model.
# Note: to use these example parameters, you may need to remove the .done files
# to make sure the make_lm_dir.py be called and tain only 3-gram model
#for order in 3; do
#rm -f ${lm_dir}/${num_word}_${order}.pocolm/.done

if [ $order == 3 ]; then
bypass_metaparam_optim_opt="--bypass-metaparameter-optimization=0.934,0.021,0.705,0.110,0.021,0.004,0.954,0.582,0.070,0.005"
else
  bypass_metaparam_optim_opt="--bypass-metaparameter-optimization=0.854,0.0722,0.5808,0.338,0.166,0.015,0.999,0.6228,0.340,0.172,0.999,0.788,0.501,0.406"
fi

if [ $stage -le 0 ]; then
  mkdir -p ${dir}/data
  mkdir -p ${dir}/data/text

  echo "$0: Getting the Data sources"

  rm ${dir}/data/text/* 2>/dev/null || true

  # Zip the combined training file.
  cat data/data.txt | gzip -c > ${dir}/data/text/train.txt.gz

  # use a subset of the annotated training data as the dev set .
  # Note: the name 'dev' is treated specially by pocolm, it automatically
  # becomes the dev set.
  
  # Shuffle the training data since it is currently sorted according to language.
  shuf ${sdir}/train/text > ${sdir}/train/text_s

  head -n $num_dev_sentences < ${sdir}/train/text_s | cut -d " " -f 2-  > ${dir}/data/text/dev.txt
  # .. and the rest of the training data as an additional data source.
  # we can later fold the dev data into this.
  tail -n +$[$num_dev_sentences+1] < ${sdir}/train/text_s | cut -d " " -f 2- >  ${dir}/data/text/ted.txt

  # for reporting perplexities, we'll use the "real" dev set.
  # (a subset of the training data is used as ${dir}/data/text/ted.txt to work
  # out interpolation weights.
  # note, we can't put it in ${dir}/data/text/, because then pocolm would use
  # it as one of the data sources.
  cut -d " " -f 2-  < ${sdir}/dev/text  > ${dir}/data/real_dev_set.txt

  # move the wordlist to lm folder
  cp ${sdir}/wordlist ${dir}/data/wordlist

fi


if [ $stage -le 1 ]; then
  # decide on the vocabulary.
  # Note: you'd use --wordlist if you had a previously determined word-list
  # that you wanted to use.
  # Note: if you have more than one order, use a certain amount of words as the
  # vocab and want to restrict max memory for 'sort',
  echo "$0: training the unpruned LM"
  min_counts='train=2 ted=1'
  wordlist=${dir}/data/wordlist

  lm_name="`basename ${wordlist}`_${order}"
  if [ -n "${min_counts}" ]; then
    lm_name+="_`echo ${min_counts} | tr -s "[:blank:]" "_" | tr "=" "-"`"
  fi
  unpruned_lm_dir=${lm_dir}/${lm_name}.pocolm
  train_lm.py  --wordlist=${wordlist} --num-splits=10 --warm-start-ratio=20  \
               --limit-unk-history=true \
               --fold-dev-into=ted ${bypass_metaparam_optim_opt} \
               --min-counts="${min_counts}" \
               ${dir}/data/text ${order} ${lm_dir}/work ${unpruned_lm_dir}

  get_data_prob.py ${dir}/data/real_dev_set.txt ${unpruned_lm_dir} 2>&1 | grep -F '[perplexity'
  #[perplexity = 157.87] over 18290.0 words
 
  mkdir -p ${dir}/data/arpa
  format_arpa_lm.py ${unpruned_lm_dir} | gzip -c > ${dir}/data/arpa/${order}gram.arpa.gz
fi
