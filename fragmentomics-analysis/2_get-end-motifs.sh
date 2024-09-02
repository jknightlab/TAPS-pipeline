#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J end-motifs

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/get-end-motifs_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/get-end-motifs_%j.err 

#SBATCH -p short 
#SBATCH -c 4
##########################################################################################

# Setting default parameter values
input_dir=$PWD
output_dir=$PWD
twoBit_reference='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/reference-genome/twoBit/GRCh38-reference_with-spike-in-sequences.2bit'


# Reading in arguments
while getopts i:o:s:r:h opt
do
	case $opt in
	i)
		input_dir=$OPTARG
		;;
	o)
		output_dir=$OPTARG
		;;
	s)
		sample_list_path=$OPTARG
		;;
	r)
		twoBit_reference=$OPTARG
		;;
	h)
		echo "Usage:	get-end-motifs.sh [-i input_dir] [-o output_dir] [-r twoBit_reference_file] [-s sample_list]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing BED files with fragment coordinate information [defaults to the working directory]"
		echo "-o		Path to output directory where to write all output files [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo "-r		Path to a twoBit file for the reference genome used during alignment [defaults to a GRCh38 twoBit file]"
		echo ""
		exit 1
		;;
	esac
done

# Validating arguments
echo "[end-motifs]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[end-motifs]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[end-motifs]:	ERROR: Output directory not found."
        exit 2
fi 

if [[ ! -f $sample_list_path ]]
then
        echo "[end-motifs]:	ERROR: Sample list file not found"
        exit 2
fi

if [[ ! -f $twoBit_reference ]]
then
        echo "[end-motifs]:	ERROR: twoBit reference file not found"
        exit 2
fi

# Outputing relevant information on how the job was run
echo "------------------------------------------------" 
echo "Run on host: "`hostname` 
echo "Operating system: "`uname -s` 
echo "Username: "`whoami` 
echo "Started at: "`date` 
echo "Executing task ${SLURM_ARRAY_TASK_ID} of job ${SLURM_ARRAY_JOB_ID} "
echo "------------------------------------------------" 

# Loading required modules and files
echo "[end-motifs]:	Reading sample list..."
readarray sampleList < $sample_list_path

# Defining path variables

# Per-task processing 
## Defining input names
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

## Fetching 5' end motifs
echo "[end-motifs]:	Fetching 5' fragment end motifs for top strand ($sampleName)..."
/well/jknight/users/awo868/software/ucsc/twoBitToFa \
	-bed="${input_dir}/${sampleName}_fragment-coordinates.bed" \
	$twoBit_reference \
	stdout | \
	awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' | \
	grep -v '^>' | \
	cut -c-4 | \
	sed '/^$/d' \
	> "${output_dir}/${sampleName}_5-prime-end-motifs_top-strand.tsv"
	
echo "[end-motifs]:	Fetching 5' fragment end motifs for bottom strand ($sampleName)..."
/well/jknight/users/awo868/software/ucsc/twoBitToFa \
	-bed="${input_dir}/${sampleName}_fragment-coordinates.bed" \
	$twoBit_reference \
	stdout | \
	awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' | \
	grep -v '^>' | \
	grep -o '....$' | \
	tr ACGTacgt TGCAtgca | \
	rev \
	> "${output_dir}/${sampleName}_5-prime-end-motifs_bottom-strand.tsv"
	
echo "[end-motifs]:	...done!"
