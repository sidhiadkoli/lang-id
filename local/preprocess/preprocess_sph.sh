#!/bin/bash
# 1. Convert compressed sph to wav.
# 2. Upsample and mono the wav file.
# 3. Convert wav to sph.

set=$1
mkdir $set/sph/tmp
dir=$set/sph/tmp
sdir=$set/sph

for fName in $sdir/*.sph; do
    name=$(basename $fName .sph)
    ../../../../../tools/sph2pipe_v2.5/sph2pipe -p -f wav $fName $dir/$name.wav
    sox $dir/$name.wav -c 1 -r 16000 $dir/$name_1.wav
    mv $dir/$name_1.wav $dir/$name.wav
    sox $dir/$name.wav $dir/$name.sph
    rm $dir/$name.wav
done

mv $dir/* $sdir/.
rmdir $dir
