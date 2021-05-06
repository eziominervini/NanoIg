#!/bin/sh


#  Path to Canu.

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

bin="/home/ezio/canu/$syst-$arch/bin"

if [ ! -d "$bin" ] ; then
  bin="/home/ezio/canu"
fi



#  File must exist: seqDB.v001.dat
#  File must exist: seqDB.v001.tig

#  File must exist: seqDB.v002.dat
#  File must exist: seqDB.v002.tig

#  File must exist: seqDB.v001.dat
#  File must exist: seqDB.v001.tig

#  File must exist: seqDB.v002.dat
#  File must exist: seqDB.v002.tig


if [ ! -e ./ighv1.unitigs.aligned.gfa ] ; then
  $bin/alignGFA \
    -T ../ighv1.utgStore 2 \
    -i ./ighv1.unitigs.gfa \
    -o ./ighv1.unitigs.aligned.gfa \
    -t 4 \
  > ./ighv1.unitigs.aligned.gfa.err 2>&1
#  File is important: ighv1.unitigs.aligned.gfa
fi


if [ ! -e ./ighv1.contigs.aligned.gfa ] ; then
  $bin/alignGFA \
    -T ../ighv1.ctgStore 2 \
    -i ./ighv1.contigs.gfa \
    -o ./ighv1.contigs.aligned.gfa \
    -t 4 \
  > ./ighv1.contigs.aligned.gfa.err 2>&1
#  File is important: ighv1.contigs.aligned.gfa
fi


if [ ! -e ./ighv1.unitigs.aligned.bed ] ; then
  $bin/alignGFA -bed \
    -T ../ighv1.utgStore 2 \
    -C ../ighv1.ctgStore 2 \
    -i ./ighv1.unitigs.bed \
    -o ./ighv1.unitigs.aligned.bed \
    -t 4 \
  > ./ighv1.unitigs.aligned.bed.err 2>&1
#  File is important: ighv1.unitigs.aligned.bed
fi


if [ -e ./ighv1.unitigs.aligned.gfa -a \
     -e ./ighv1.contigs.aligned.gfa -a \
     -e ./ighv1.unitigs.aligned.bed ] ; then
  echo GFA alignments updated.
  exit 0
else
  echo GFA alignments failed.
  exit 1
fi
