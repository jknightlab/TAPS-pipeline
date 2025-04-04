#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J get-unmapped-reads

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/extract-unaligned-reads_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/extract-unaligned-reads_%j.err 
#SBATCH -p short 
#SBATCH -c 6
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
		echo "Usage:	extract-unmapped-reads.sh [-i input_dir] [-o output_dir] [-s sample_list_path]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing full/unfiltered BAM files to be used for read extraction [defaults to the working directory]"
		echo "-o		Path to output directory where to write FASTQ files with unaligned reads only [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo ""
		exit 1
		;;
	esac
done

# Validating arguments
echo "[extract-unmapped-reads]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[extract-unmapped-reads]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[extract-unmapped-reads]:	ERROR: Output directory not found."
        exit 2
fi 

if [[ ! -f $sample_list_path ]]
then
        echo "[extract-unmapped-reads]:	ERROR: Sample list file not found"
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
echo "[extract-unmapped-reads]:	Loading modules..."
module load SAMtools/1.18-GCC-12.3.0

# Parsing input file
echo "[extract-unmapped-reads]:	Reading sample list..."
readarray sampleList < $sample_list_path

#  Parallelising process by sample
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

# Extracting unmapped reads
echo "[extract-unmapped-reads]: Extracting reads that did not mapped to the human genome and converting to FASTQ ($sampleName)..."
samtools view -f 13 "${input_dir}/${sampleName}.bam" | \
	samtools fastq -1 "${output_dir}/${sampleName}_unmapped-reads_1.fastq.gz" -2 "${output_dir}/${sampleName}_unmapped-reads_2.fastq.gz"

echo "[extract-unmapped-reads]: ...done!"
