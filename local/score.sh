#!/bin/bash
# Created by Sidhi Adkoli for language identification project (COMS 6998).

[ -f ./path.sh ] && . ./path.sh
. parse_options.sh || exit 1;

dir=$3
utt2langdir=$1

cat $dir/log/decode.*.log > $dir/foo

cat $dir/foo | grep -v "#" | grep -v "WARNING .*gmm" | grep -v "LOG .*gmm" | \
 grep -v "gmm-" | grep -v "apply-cmvn" | grep -v "transform" | grep -v "ark:-" | \
 grep -v "nnet3" | grep -v "lattice"  | LC_ALL=C sort > $dir/text

rm $dir/foo

rm -f $dir/score.txt

# Get lang score.
python3 local/get_lang_score.py $utt2langdir $dir/text #$dir/score_*/ctm
