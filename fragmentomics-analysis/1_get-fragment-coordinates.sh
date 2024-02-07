#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J fragment-coords

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/get-fragment-coordinates_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/get-fragment-coordinates_%j.err 

#SBATCH -p short 
#SBATCH -c 4
##########################################################################################

# Setting default parameter values
input_dir=$PWD
output_dir=$PWD

# Reading in arguments
while getopts i:o:s:h opt
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
	h)
		echo "Usage:	get-fragment-coordinates.sh [-i input_dir] [-o output_dir] [-s sample_list_path]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing BAM files from which to getch fragment coordinates [defaults to the working directory]"
		echo "-o		Path to output directory where to write final BED files [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo ""
		exit 1
		;;
	esac
done

## Validating arguments
echo "[fragment-coordinates]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[fragment-coordinates]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[fragment-coordinates]:	ERROR: Output directory not found."
        exit 2
fi 

if [[ ! -f $sample_list_path ]]
then
        echo "[fragment-coordinates]:	ERROR: Sample list file not found"
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

# Loading required modules
echo "[fragment-coordinates]:	Loading required modules..."
module load samtools/1.8-gcc5.4.0

echo "[fragment-coordinates]:	Reading sample list..."
readarray sampleList < $sample_list_path

#  Parallelising process by sample
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')
echo "[fragment-coordinates]:	Processing sample $sampleName..."	

# Retrieving coordinates
echo "[fragment-coordinates]:	Fetching fragment coordinates from BAM file ($sampleName)..."
samtools view -F 3100 -f 3 -q 10 \
	"${input_dir}/${sampleName}.qced.sorted.markdup.bam" | \
	cut -f 1,3,4,9 | \
	awk '{print $2"\t"$3-1"\t"$3-1+$4,"\t"$1}' \
	> "${output_dir}/${sampleName}_fragment-coordinates.bed"

echo "[fragment-coordinates]:	...done!"

