#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J check-identity

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/check-identity-1_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/check-identity-1_%j.err 
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
		echo "Usage:	add-read-groups.sh [-i input_dir] [-o output_dir] [-s sample_list_path]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing BAM files for read grouping [defaults to the working directory]"
		echo "-o		Path to output directory where to write read-grouped BAM file [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo ""
		exit 1
		;;
	esac
done

## Validating arguments
echo "[check-identity]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[check-identity]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[check-identity]:	ERROR: Output directory not found."
        exit 2
fi 

if [[ ! -f $sample_list_path ]]
then
        echo "[check-identity]:	ERROR: Sample list file not found"
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
echo "[check-identity]:		Loading modules..."
module load Java/11.0.2
module load picard/2.23.0-Java-11

# Parsing input file
echo "[check-identity]:		Reading sample list..."
readarray sampleList < $sample_list_path

## Creating output directories
if [[ ! -d "${output_dir}/tmp" ]]
then
        mkdir "${output_dir}/tmp"
fi

#  Parallelising process by sample
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')
echo "[check-identity]:       Processing sample $sampleName..."	

echo "[check-identity]:		Adding readgroups to BAM file..."	
java -jar $EBROOTPICARD/picard.jar AddOrReplaceReadGroups \
	I="${input_dir}/${sampleName}.qced.sorted.markdup.bam" \
    O="${output_dir}/tmp/${sampleName}.qced.sorted.markdup.RG.bam" \
    RGID="${sampleName}" \
    RGLB="TAPS" \
    RGPL="ILLUMINA" \
    RGPU="${sampleName}" \
    RGSM="${sampleName}"

echo "[check-identity]:		...done!"	
