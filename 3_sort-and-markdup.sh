#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J mrkdup

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/sort-and-markdup_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/sort-and-markdup_%j.err 
#SBATCH -p long 
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
		echo "Usage:	sort-and-markdup.sh [-i input_dir] [-o output_dir] [-s sample_list_path]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing BAM files for sorting and marking of PCR duplicates [defaults to the working directory]"
		echo "-o		Path to output directory where to write the sorted and marked BAM files [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo ""
		exit 1
		;;
	esac
done

# Validating arguments
echo "[sort-and-markdup]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[bwa-mem]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[bwa-mem]:	ERROR: Output directory not found."
        exit 2
fi 

if [[ ! -f $sample_list_path ]]
then
        echo "[bwa-mem]:	ERROR: Sample list file not found"
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
echo "[sort-and-markdup]:	Loading modules..."
module load Java/11.0.2
module load samtools/1.8-gcc5.4.0
module load picard/2.23.0-Java-11

# Parsing input file
echo "[sort-and-markdup]:	Reading sample list..."
readarray sampleList < $sample_list_path

#  Parallelising process by sample
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

# Sorting BAM file and marking duplicated reads
if [[ ! -d "${output_dir}/tmp" ]]
then
	mkdir "${output_dir}/tmp"
fi

echo "[sort-and-markdup]: Filtering and sorting $sampleName alignment..."
samtools view -h -q 10 "${input_dir}/${sampleName}.bam" | \
	samtools sort -@ 10 -O bam > "${output_dir}/tmp/${sampleName}.bam"

echo "[sort-and-markdup]: Marking read duplicates..."
java -jar $EBROOTPICARD/picard.jar MarkDuplicates \
	I="${output_dir}/tmp/${sampleName}.bam" \
	O="${output_dir}/${sampleName}.qced.sorted.markdup.bam" \
	M="${output_dir}/${sampleName}_marked_dup_metrics.txt" 

# Removing intermediary files
echo "[sort-and-markdup]: Cleaning up..."
rm "${output_dir}/tmp/${sampleName}.bam"

echo "[sort-and-markdup]: ...done!"
