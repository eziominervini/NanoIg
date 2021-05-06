#!/bin/sh


#  Path to Canu.

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

bin="/home/ezio/canu/$syst-$arch/bin"

if [ ! -d "$bin" ] ; then
  bin="/home/ezio/canu"
fi



#  Store must exist: unitigging/ighv1.gkpStore
#  Store must exist: unitigging/ighv1.ovlStore

#  File must exist: evalues

#  Discover the job ID to run, from either a grid environment variable and a
#  command line offset, or directly from the command line.
#
if [ x$CANU_LOCAL_JOB_ID = x -o x$CANU_LOCAL_JOB_ID = xundefined -o x$CANU_LOCAL_JOB_ID = x0 ]; then
  baseid=$1
  offset=0
else
  baseid=$CANU_LOCAL_JOB_ID
  offset=$1
fi
if [ x$offset = x ]; then
  offset=0
fi
if [ x$baseid = x ]; then
  echo Error: I need CANU_LOCAL_JOB_ID set, or a job index on the command line.
  exit
fi
jobid=`expr $baseid + $offset`
if [ x$CANU_LOCAL_JOB_ID = x ]; then
  echo Running job $jobid based on command line options.
else
  echo Running job $jobid based on CANU_LOCAL_JOB_ID=$CANU_LOCAL_JOB_ID and offset=$offset.
fi

if [ -e ../ighv1.ctgStore/seqDB.v001.tig -a -e ../ighv1.utgStore/seqDB.v001.tig ] ; then
  exit 0
fi

if [ ! -e ../ighv1.ctgStore -o \
     ! -e ../ighv1.utgStore ] ; then
  $bin/bogart \
    -G ../ighv1.gkpStore \
    -O ../ighv1.ovlStore \
    -o ./ighv1 \
    -gs 5000 \
    -eg 0.144 \
    -eM 0.144 \
    -mo 300 \
    -dg 6 \
    -db 6 \
    -dr 3 \
    -ca 2100 \
    -cp 200 \
    -threads 4 \
    -M 16 \
    -unassembled 2 0 1.0 0.5 3 \
    > ./unitigger.err 2>&1 \
  && \
  mv ./ighv1.ctgStore ../ighv1.ctgStore \
  && \
  mv ./ighv1.utgStore ../ighv1.utgStore
fi

if [ ! -e ../ighv1.ctgStore -o \
     ! -e ../ighv1.utgStore ] ; then
  echo bogart appears to have failed; no ighv1.ctgStore or ighv1.utgStore.
  exit 1
fi


#  File is important: ighv1.unitigs.gfa
#  File is important: ighv1.contigs.gfa

#  File is important: seqDB.v001.dat
#  File is important: seqDB.v001.tig

#  File is important: seqDB.v001.dat
#  File is important: seqDB.v001.tig

if [ ! -e ../ighv1.ctgStore/seqDB.v001.sizes.txt ] ; then
  $bin/tgStoreDump \
    -G ../ighv1.gkpStore \
    -T ../ighv1.ctgStore 1 \
    -sizes -s 5000 \
   > ../ighv1.ctgStore/seqDB.v001.sizes.txt
fi

#  File is important: seqDB.v001.sizes.txt

exit 0
