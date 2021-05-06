# NanoIg
NanoIg is a pipeline for IGHV mutational status analysis from nanopore generated reads. It uses bwa mem for reads alignment on the human chr14 reference and calculate clonality.
After clonality reads are filtered for clonal VH gene and used for generate consensus by canu assembly and medaka consensus tools.
Generated consensus sequences are than used to interrogate IMGT/V-Quest for mutational status assesment. Finally NanoIg generates a report.
NanoIg assumes amplicons produced by using BIOMED-2 FR1 primers set.

Prerequisites and dependencies:
python3
perl5
pip
firefox browser
conda
medaka

NanoIg Pipeline runs in medaka environment.

To install the other dependecies run:

    conda activate medaka

    path/to/NanoIg/setbash.sh

Data Folder Structure:

Data_folder
	fastq
	   Barcode01
	   Barcode02
	   ..
	   Barcode##

To run NanoIG Pipe run:

	conda activate medaka
	
	path/to/NanoIg.sh -i path/to/Data_folder -r path/to/NanoIg_package_bash

Pipeline will produce several ouputs:
A PIPE folder containg all data produced step by step and other files containing consensus sequences IMGT/V-Quest analysis results and a .doc final report. 


