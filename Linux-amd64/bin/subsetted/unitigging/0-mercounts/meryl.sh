#!/bin/sh


#  Path to Canu.

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

bin="/home/ezio/canu/$syst-$arch/bin"

if [ ! -d "$bin" ] ; then
  bin="/home/ezio/canu"
fi


#  Store must exist: unitigging/ighv1.gkpStore

#  Purge any previous intermediate result.  Possibly not needed, but safer.

rm -f ./ighv1.ms22.WORKING*

$bin/meryl \
  -B -C -L 2 -v -m 22 -threads 4 -memory 6553 \
  -s ../ighv1.gkpStore \
  -o ./ighv1.ms22.WORKING \
&& \
mv ./ighv1.ms22.WORKING.mcdat ./ighv1.ms22.mcdat \
&& \
mv ./ighv1.ms22.WORKING.mcidx ./ighv1.ms22.mcidx

#  File is important: ighv1.ms22.mcdat

#  File is important: ighv1.ms22.mcidx


#  Dump a histogram

$bin/meryl \
  -Dh -s ./ighv1.ms22 \
>  ./ighv1.ms22.histogram.WORKING \
2> ./ighv1.ms22.histogram.info \
&& \
mv -f ./ighv1.ms22.histogram.WORKING ./ighv1.ms22.histogram

#  File is important: ighv1.ms22.histogram

#  File is important: ighv1.ms22.histogram.info


#  Compute a nice kmer threshold.

$bin/estimate-mer-threshold \
  -h ./ighv1.ms22.histogram \
  -c 4 \
>  ./ighv1.ms22.estMerThresh.out.WORKING \
2> ./ighv1.ms22.estMerThresh.err \
&& \
mv ./ighv1.ms22.estMerThresh.out.WORKING ./ighv1.ms22.estMerThresh.out

#  File is important: ighv1.ms22.estMerThresh.out

#  File is important: ighv1.ms22.estMerThresh.err


exit 0
