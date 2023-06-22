#!/usr/bin/bash

## Author:	Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J trim-galore

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/trim-galore_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/trim-galore_%j.err 

#SBATCH -p short
#SBATCH -c 5  

# Outputing relevant information on how the job was run
echo "------------------------------------------------" 
echo "Run on host: "`hostname` 
echo "Operating system: "`uname -s` 
echo "Username: "`whoami` 
echo "Started at: "`date` 
echo "Executing task ${SLURM_ARRAY_TASK_ID} of job ${SLURM_ARRAY_JOB_ID} "
echo "------------------------------------------------" 


########################################################################################## 
# General processing
## Reading in arguments
echo "===== TAPS pipeline step 1: Read trimming with TrimGalore! ====="
echo ""
echo "[trim-galore]:	Validating arguments..."
if [[ ! -f $1 ]]
then
	echo "[trim-galore]:	ERROR: Sample list file not found."
	exit 2
fi

if [[ ! -d $2 ]]
then
	echo "[trim-galore]:	ERROR: Output directory not found."
	exit 2
fi 

echo "[trim-galore]:	Reading sample list..."
readarray sampleList < $1
outDir=$2

## Loading required modules
echo "[trim-galore]:	Loading modules..."
module load Java/11.0.2
module load Python/3.8.2-GCCcore-9.3.0
module load FastQC/0.11.9-Java-11
module load cutadapt/2.10-GCCcore-9.3.0-Python-3.8.2

## Defining path variables
trimGalore='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/analysis/software/TrimGalore-0.6.10/trim_galore'

# Per-task processing 
## Defining inputs per task
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

## Running command
echo "[trim-galore]:	Running TrimGalore! for sample ${sampleName}..."
$trimGalore \
	--paired \
	--length 35 \
	--gzip \
	--fastqc \
	--cores 2 \
	-o $outDir \
	"${sampleName}_1.fastq.gz" \
	"${sampleName}_2.fastq.gz"

echo "[trim-galore]:	...done!"
