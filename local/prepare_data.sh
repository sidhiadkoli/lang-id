#!/bin/bash
#
# Copyright  2014  Nickolay V. Shmyrev
#            2014  Brno University of Technology (Author: Karel Vesely)
#            2016  Johns Hopkins University (Author: Daniel Povey)
# Apache 2.0
# Modified by Sidhi Adkoli for language identification project (COMS 6998).


# To be run from one directory above this script.

. ./path.sh

export LC_ALL=C

#Create files for english, mandarin and arabic.

lang=english

# Prepare: dev, test, train,
for set in dev test train; do
  dir=data_lang/$lang/$set.orig
  mkdir -p $dir

  # Merge transcripts into a single 'stm' file, do some mappings:
  # - <F0_M> -> <o,f0,male> : map dev stm labels to be coherent with train + test,
  # - <F0_F> -> <o,f0,female> : --||--
  # - (2) -> null : remove pronunciation variants in transcripts, keep in dictionary
  # - <sil> -> null : remove marked <sil>, it is modelled implicitly (in kaldi)
  # - (...) -> null : remove utterance names from end-lines of train
  # - it 's -> it's : merge words that contain apostrophe (if compound in dictionary, local/join_suffix.py)
  { # Add STM header, so sclite can prepare the '.lur' file
    echo ';;
;; LABEL "o" "Overall" "Overall results"
;; LABEL "f0" "f0" "Wideband channel"
;; LABEL "f2" "f2" "Telephone channel"
;; LABEL "male" "Male" "Male Talkers"
;; LABEL "female" "Female" "Female Talkers"
;;'
    # Process the STMs
    cat db/sa3505_data/$lang/$set/stm/*.stm | sort -k1,1 -k2,2 -k4,4n | \
      sed -e 's:<F0_M>:<o,f0,male>:' \
          -e 's:<F0_F>:<o,f0,female>:' \
          -e 's:([0-9])::g' \
          -e 's:<sil>::g' \
          -e 's:([^ ]*)$::' | \
      awk '{ $2 = "A"; print $0; }'
  } | local/join_suffix.py > $dir/stm

  # Prepare 'text' file
  # - {NOISE} -> [NOISE] : map the tags to match symbols in dictionary
  cat $dir/stm | grep -v -e 'ignore_time_segment_in_scoring' -e ';;' | \
    awk '{ printf ("%s-%07d-%07d", $1, $4*100, $5*100);
           for (i=7;i<=NF;i++) { printf(" %s", $i); }
           printf("\n");
         }' | tr '{}' '[]' | sort -k1,1 > $dir/text || exit 1

  # Prepare 'segments', 'utt2spk'
  cat $dir/text | cut -d" " -f 1 | awk -F"-" '{printf("%s %s %07.2f %07.2f\n", $0, $1, $2/100.0, $3/100.0)}' > $dir/segments
  cat $dir/segments | awk '{print $1, $2}' > $dir/utt2spk

  cat $dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $dir/spk2utt

  # Prepare 'wav.scp'
  cat $dir/spk2utt | awk -v lang=$lang -v set=$set -v pwd=$PWD '{ printf("%s sph2pipe -f wav -p %s/db/sa3505_data/%s/%s/sph/%s.sph |\n", $1, pwd, lang,  set, $1); }' > $dir/wav.scp

  utils/data/modify_speaker_info.sh --seconds-per-spk-max 180 data_lang/$lang/${set}.orig data_lang/$lang/${set}
  
  # Check that data dirs are okay!
  utils/validate_data_dir.sh --no-feats $dir || exit 1
done


for lang in mandarin arabic ; do
  # Prepare: dev, test, train,
  for set in dev test train; do
    dir=data_lang/$lang/$set
    mkdir -p $dir

    # combine data.
    
    if [ $lang == "mandarin" ]; then
      cat db/sa3505_data/$lang/$set/stm/*.txt | sort > $dir/stm
    else
      # arabic data has too many files and cat-ing it causes issues.
      cp db/sa3505_data/$lang/$set/$set.txt $dir/stm
    fi

    # Prepare 'text' file
    cat $dir/stm | \
      awk '{ printf ("%s", $1);
             for (i=6;i<=NF;i++) { printf(" %s", $i); }
             printf("\n");
           }' | sort -k1,1 > $dir/text || exit 1

    # Prepare 'segments', 'utt2spk', 'spk2utt'
    cat $dir/stm | awk -F ' ' '{printf("%s %s %s %s\n", $1, $2, $4, $5)}' > $dir/segments

    cat $dir/stm | awk -F ' ' '{printf("%s %s\n", $1, $3)}' > $dir/utt2spk
  
    cat $dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $dir/spk2utt
  
    # Prepare 'wav.scp'
    if [ $lang == "mandarin" ]; then
      cat $dir/stm | awk -v lang=$lang -v set=$set -v pwd=$PWD '{ printf("%s sph2pipe -f wav -p %s/db/sa3505_data/%s/%s/sph/%s.sph |\n", $2, pwd, lang,  set, $2); }' | sort | uniq > $dir/wav.scp
    else  
      cat $dir/stm | awk -v lang=$lang -v set=$set -v pwd=$PWD '{ printf("%s %s/db/sa3505_data/%s/%s/sph/%s.wav\n", $2, pwd, lang,  set, $2); }' > $dir/wav.scp
    fi;

    # Check that data dirs are okay!
    utils/validate_data_dir.sh --no-feats $dir || exit 1
  done
done

# Now combine the data
for set in dev test train ; do
    dir=data/$set
    mkdir -p $dir

    cat data_lang/*/$set/text | sort > $dir/text
    cat data_lang/*/$set/utt2spk | sort > $dir/utt2spk
    cat data_lang/*/$set/segments | sort > $dir/segments
    cat data_lang/*/$set/wav.scp | sort > $dir/wav.scp
     
    python local/generate_utt2lang.py $dir/text $dir

    cat $dir/utt2spk | utils/utt2spk_to_spk2utt.pl > $dir/spk2utt

    utils/validate_data_dir.sh --no-feats $dir || exit 1
done

cat data/*/text | sort > data/foo
cut -d ' ' -f 2- data/foo > data/data.txt
rm data/foo


