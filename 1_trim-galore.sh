#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J trim-galore

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/trim-galore_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/trim-galore_%j.err 

#SBATCH -p short
#SBATCH -c 3

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
		echo "Usage:	trim-galore.sh [-i input_dir] [-o output_dir] [-s sample_list_path]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing FASTQ files to be trimmed [defaults to the working directory]"
		echo "-o		Path to output directory where to write trimmed FASTQ files [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo ""
		exit 1
		;;
	esac
done

# Validating arguments
echo "[trim-galore]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
        echo "[trim-galore]:	ERROR: Input directory not found."
        exit 2
fi 

if [[ ! -d $output_dir ]]
then
        echo "[trim-galore]:	ERROR: Output directory not found."
        exit 2
fi 


if [[ ! -f $sample_list_path ]]
then
        echo "[trim-galore]:	ERROR: Sample list file not found"
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

# Reading sample list
echo "[trim-galore]:	Reading sample list..."
readarray sampleList < $sample_list_path


# Parallelising process by sample
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')
echo "[trim-galore]:	Processing files for sample ${sampleName}..."

# Loading required modules
echo "[trim-galore]:	Loading modules..."
module load Java/11.0.2
module load Python/3.8.2-GCCcore-9.3.0
module load FastQC/0.11.9-Java-11
module load cutadapt/2.10-GCCcore-9.3.0-Python-3.8.2

# Defining path variables
trimGalore='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/analysis/software/TrimGalore-0.6.10/trim_galore'

# Running command
echo "[trim-galore]:	Running TrimGalore! for sample ${sampleName}..."
$trimGalore \
	--paired \
	--length 35 \
	--gzip \
	--fastqc \
	--cores 2 \
	-o $output_dir \
	"${input_dir}/${sampleName}_1.fastq.gz" \
	"${input_dir}/${sampleName}_2.fastq.gz"

echo "[trim-galore]:	...done!"
