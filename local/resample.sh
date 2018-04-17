for set in train test dev ; do
    for f in $set/sph/* ; do
        sox -r 8000 $f $set/sph/tmp.sph
        sox -r 16000 $set/sph/tmp.sph $f
        rm $set/sph/tmp.sph
    done
done
