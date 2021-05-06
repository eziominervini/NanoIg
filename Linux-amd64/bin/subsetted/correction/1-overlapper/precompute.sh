#!/bin/sh


#  Path to Canu.

syst=`uname -s`
arch=`uname -m | sed s/x86_64/amd64/`

bin="/home/ezio/canu/$syst-$arch/bin"

if [ ! -d "$bin" ] ; then
  bin="/home/ezio/canu"
fi


#  Store must exist: correction/ighv1.gkpStore

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

if [ $jobid -eq 1 ] ; then
  rge="-b 1 -e 484"
  job="000001"
fi


if [ x$job = x ] ; then
  echo Job partitioning error.  jobid $jobid is invalid.
  exit 1
fi

if [ ! -d ./blocks ]; then
  mkdir -p ./blocks
fi

if [ -e ./blocks/$job.dat ]; then
  echo Job previously completed successfully.
  exit
fi

#  Remove any previous result.
rm -f ./blocks/$job.input.dat


$bin/gatekeeperDumpFASTQ \
  -G ../ighv1.gkpStore \
  $rge \
  -nolibname \
  -noreadname \
  -fasta \
  -o ./blocks/$job.input \
|| \
mv -f ./blocks/$job.input.fasta ./blocks/$job.input.fasta.FAILED


if [ ! -e ./blocks/$job.input.fasta ] ; then
  echo Failed to extract fasta.
  exit 1
fi

#  File must exist: ighv1.ms16.frequentMers.ignore.gz

echo ""
echo Starting mhap precompute.
echo ""

#  So mhap writes its output in the correct spot.
cd ./blocks

java -d64 -server -Xmx6144m \
  -jar  $bin/../share/java/classes/mhap-2.1.3.jar  \
  --repeat-weight 0.9 --repeat-idf-scale 10 -k 16 \
  --store-full-id \
  --num-hashes 512 \
  --num-min-matches 3 \
  --ordered-sketch-size 1536 \
  --ordered-kmer-size 12 \
  --threshold 0.83 \
  --filter-threshold 0.000506177310018028 \
  --min-olap-length 300 \
  --num-threads 8 \
  -f  ../../0-mercounts/ighv1.ms16.frequentMers.ignore.gz  \
  -p  ./$job.input.fasta  \
  -q  .  \
&& \
mv -f ./$job.input.dat ./$job.dat

if [ ! -e ./$job.dat ] ; then
  echo Mhap failed.
  exit 1
fi

#  Clean up, remove the fasta input
rm -f ./$job.input.fasta

#  File is important: $job.dat

exit 0
