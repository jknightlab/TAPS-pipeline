#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J mapstats

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/get-mapping-stats_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/get-mapping-stats_%j.err 

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
		echo "Usage:	get-mapping-stats.sh [-i input_dir] [-o output_dir] [-s sample_list_path]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing sorted BAM files for for methylation bias estimation [defaults to the working directory]"
		echo "-o		Path to output directory where to store methylation bias plots [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo ""
		exit 1
		;;
	esac
done

# Validating arguments
echo "[mapping-stats]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[mapping-stats]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[mapping-stats]:	ERROR: Output directory not found."
        exit 2
fi 

if [[ ! -f $sample_list_path ]]
then
        echo "[mapping-stats]:	ERROR: Sample list file not found"
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

## Loading required modules
echo "[mapping-stats]:	Loading modules..."
module load Java/11.0.2
module load picard/2.23.0-Java-11
module load samtools/1.8-gcc5.4.0

# Parsing input file
echo "[mapping-stats]:       Reading sample list..."
readarray sampleList < $sample_list_path

## Creating output directories
echo "[mapping-stats]:	Setting up output directory structure..."
if [[ ! -d "${output_dir}/mapping-stats" ]]
then
        mkdir "${output_dir}/mapping-stats"
fi

if [[ ! -d "${output_dir}/insert-sizes" ]]
then
        mkdir "${output_dir}/insert-sizes"
fi

if [[ ! -d "${output_dir}/genome-coverage" ]]
then
        mkdir "${output_dir}/genome-coverage"
fi

#  Parallelising process by sample
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')
echo "[mapping-stats]:       Processing sample $sampleName..."	

echo "[mapping-stats]:       Computing mapping statistics with samtools..."	
samtools stats -d "${input_dir}/${sampleName}.qced.sorted.markdup.bam" > "${output_dir}/mapping-stats/${sampleName}_mapping-statistics.txt"


echo "[mapping-stats]:       Checking insert size distirbution with picard..."	
java -jar $EBROOTPICARD/picard.jar CollectInsertSizeMetrics \
	I="${input_dir}/${sampleName}.qced.sorted.markdup.bam" \
    O="${output_dir}/insert-sizes/${sampleName}_insert_size_metrics.txt" \
    H="${output_dir}/insert-sizes/${sampleName}_insert_size_histogram.pdf" \
    M=0.001

echo "[mapping-stats]:       Computing genome coverage with BEDtools..."	
/well/jknight/users/awo868/software/bedtools genomecov \
	-ibam "${input_dir}/${sampleName}.qced.sorted.markdup.bam" \
	> "${output_dir}/genome-coverage/${sampleName}_genome-coverage.txt"

echo "[mapping-stats]:       ...done!"	
