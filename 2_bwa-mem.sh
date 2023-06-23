#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/bwa-mem_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/bwa-mem_%j.err 
#SBATCH -p long 
#SBATCH -c 10

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
echo "===== TAPS pipeline step 2: Read alignment with BWA MEM ====="
echo ""
echo "[bwa-mem]:	Validating arguments..."
if [[ ! -f $1 ]]
then
	echo "[bwa-mem]:	ERROR: Sample list file not found."
	exit 2
fi

if [[ ! -d $2 ]]
then
	echo "[bwa-mem]:	ERROR: Output directory not found."
	exit 2
fi 

echo "[bwa-mem]:	Reading sample list..."
readarray sampleList < $1
outDir=$2

## Loading BWA module
echo "[bwa-mem]:	Loading modules..."
module load BWA/0.7.17-GCC-9.3.0 

## Defining path variables
referenceGenome='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/results/TAPS-pipeline/bwa-mem/reference-genome/GRCh38-reference_with-spike-in-sequences.fasta.gz'

# Per-task processing 
## Defining input and output names
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

## Running BWA
echo "[bwa-mem]:	Aligning reads with bwa mem for $sampleName..."
bwa mem \
	-I 500,120,1000,20 \
	$referenceGenome \
	"${sampleName}_1_val_1.fq.gz" \
	"${sampleName}_2_val_2.fq.gz" > "${outDir}/${sampleName}.sam"

echo "[bwa-mem]: ...done!"
