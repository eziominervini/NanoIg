#!/bin/sh


#  Path to Canu.

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

bin="/home/ezio/canu/$syst-$arch/bin"

if [ ! -d "$bin" ] ; then
  bin="/home/ezio/canu"
fi


#  Store must exist: correction/ighv1.gkpStore

#  Purge any previous intermediate result.  Possibly not needed, but safer.

rm -f ./ighv1.ms16.WORKING*

$bin/meryl \
  -B -C -L 2 -v -m 16 -threads 4 -memory 6553 \
  -s ../ighv1.gkpStore \
  -o ./ighv1.ms16.WORKING \
&& \
mv ./ighv1.ms16.WORKING.mcdat ./ighv1.ms16.mcdat \
&& \
mv ./ighv1.ms16.WORKING.mcidx ./ighv1.ms16.mcidx

#  File is important: ighv1.ms16.mcdat

#  File is important: ighv1.ms16.mcidx


#  Dump a histogram

$bin/meryl \
  -Dh -s ./ighv1.ms16 \
>  ./ighv1.ms16.histogram.WORKING \
2> ./ighv1.ms16.histogram.info \
&& \
mv -f ./ighv1.ms16.histogram.WORKING ./ighv1.ms16.histogram

#  File is important: ighv1.ms16.histogram

#  File is important: ighv1.ms16.histogram.info


#  Compute a nice kmer threshold.

$bin/estimate-mer-threshold \
  -h ./ighv1.ms16.histogram \
  -c 52 \
>  ./ighv1.ms16.estMerThresh.out.WORKING \
2> ./ighv1.ms16.estMerThresh.err \
&& \
mv ./ighv1.ms16.estMerThresh.out.WORKING ./ighv1.ms16.estMerThresh.out

#  File is important: ighv1.ms16.estMerThresh.out

#  File is important: ighv1.ms16.estMerThresh.err


exit 0
