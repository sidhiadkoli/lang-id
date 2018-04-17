#!/bin/bash
# Combine data from different languages to a single folder.

sdir=../data_lang
dir=../data

for set in dev test train; do
    for file in segments text utt2spk spk2utt "wav.scp"; do
        for lang in mandarin english arabic; do
            cat $sdir/$lang/$set/$file >> $dir/$set/output_$file
        done
        
        cat $dir/$set/output_$file | LC_ALL=C sort > $dir/$set/$file
        rm $dir/$set/output_$file
    done
done
