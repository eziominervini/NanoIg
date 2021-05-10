#!/bin/bash

	while getopts i:b:r: flag
do
    case "${flag}" in
        i) input=${OPTARG};;
	b) barcode=${OPTARG};;
	r) run=${OPTARG};;
    esac
done


cat $input/fastq/$barcode/*.fastq > $input/fastq/$barcode/total.fastq
seqtk seq -a $input/fastq/$barcode/total.fastq > $input/fastq/$barcode/total.fasta


cd $input/PIPE/Clonality
bwa mem -x ont2d -t 8 $run/Chr14/chr14.fa $input/fastq/$barcode/total.fasta | samtools sort -o $input/PIPE/Clonality/$barcode/sample.sorted.bam -T reads.tmp
samtools index $input/PIPE/Clonality/$barcode/sample.sorted.bam
bedtools multicov -bams $input/PIPE/Clonality/$barcode/sample.sorted.bam -bed $run/Chr14/UCSC_hg38_VH_genes.bed > $input/PIPE/Clonality/$barcode/coverage.bed
awk '{ if($5 >= 500) { print }}' $input/PIPE/Clonality/$barcode/coverage.bed > $input/PIPE/Clonality/$barcode/Clonal_candidate.bed
cd $input/PIPE/Clonality/$barcode/
gnuplot $run/PlotClone


peaks=$(wc --lines < $input/PIPE/Clonality/$barcode/Clonal_candidate.bed)
	for j in `seq 1 $peaks`; do
		start=$(awk NR==$j'{print $2}' $input/PIPE/Clonality/$barcode/Clonal_candidate.bed)
		end=$(awk NR==$j'{print $3}' $input/PIPE/Clonality/$barcode/Clonal_candidate.bed)
		gene=$(awk NR==$j'{print $4}' $input/PIPE/Clonality/$barcode/Clonal_candidate.bed)
		name=$barcode-$gene
		samtools view -h $input/PIPE/Clonality/$barcode/sample.sorted.bam chr14:$start-$end | cut -f1 | sort | uniq > $input/PIPE/$barcode/$name.txt
		seqtk subseq $input/fastq/$barcode/total.fastq $input/PIPE/$barcode/$name.txt > $input/PIPE/$barcode/$name.fastq
		$run/seqkit rmdup $input/PIPE/$barcode/$name.fastq -n -o $input/PIPE/$barcode/$name-clean.fastq -D $input/PIPE/$barcode/duplicates$j.txt
		$run/seqkit seq -M 350 -g $input/PIPE/$barcode/$name-clean.fastq > $input/PIPE/$barcode/$name-filtered.fastq
		$run/seqkit seq -m 200 -g $input/PIPE/$barcode/$name-filtered.fastq > $input/PIPE/$barcode/$name-filtered2.fastq
		j=$(($j + 1))
		cd $input/PIPE/$barcode/
		error=0.2
		test="0"

		while [ "$test" -eq 0 ]; do
			rm -rf $input/PIPE/$barcode/Assembly-$name/
			error=$(echo $error + 0.2 | bc)
			$run/canu-1.8/Linux-amd64/bin/canu -d Assembly-$name -p ighv  MhapMerSize=23 correctedErrorRate=$error minReadLength=200 minOverlapLength=100 genomeSize=1.0k rawErrorRate=0.5 -nanopore-raw $input/PIPE/$barcode/$name-filtered2.fastq
			$run/canu-1.8/Linux-amd64/bin/canu -d Assembly-$name -p ighv  MhapMerSize=23 correctedErrorRate=$error minReadLength=200 minOverlapLength=100 genomeSize=1.0k rawErrorRate=0.5 -nanopore-raw $input/PIPE/$barcode/$name-filtered2.fastq
			
			test=$(wc -c < $input/PIPE/$barcode/Assembly-$name/ighv.contigs.fasta)
		done
		
		cut -f1 -d"c" $input/PIPE/$barcode/Assembly-$name/ighv.contigs.fasta | $run/seqkit fx2tab | $run/csvtk mutate -H -t -f 1 -p "reads=(.+)" | awk -F "\t" '$4>20' | $run/seqkit tab2fx > $input/PIPE/$barcode/Assembly-$name/Filtered_contigs.fasta

	
		
		$run/medaka_consensus -i $input/PIPE/$barcode/$name-filtered2.fastq -d $input/PIPE/$barcode/Assembly-$name/Filtered_contigs.fasta -o $input/PIPE/$barcode/Assembly-$name -t 1 -m r941_min_high_g303
		python $run/MaskPrimers.py align -s $input/PIPE/$barcode/Assembly-$name/consensus.fasta -p $run/For_primers.fasta --maxlen 50 --maxerror 0.5 --mode mask --pf VPRIMER --outname Assembly-$name-FWD
		python $run/MaskPrimers.py align -s $input/PIPE/$barcode/Assembly-$name/Assembly-$name-FWD_primers-pass.fasta -p $run/Rev_primer.fasta --maxlen 50 --maxerror 0.7 --mode mask --pf JPRIMER --revpr --skiprc --outname Assembly-$name-REV
		sed 's/N//g' $input/PIPE/$barcode/Assembly-$name/Assembly-$name-REV_primers-pass.fasta | awk '/^[>;]/ { if (seq) { print seq }; seq=""; print } /^[^>;]/ { seq = seq $0 } END { print seq }' | sed "s/>/\>$name:/g" >> $input/Results.fasta
	
	done

