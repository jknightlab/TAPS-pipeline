#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/check-insert-size_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/check-insert-size_%j.err 

#SBATCH -p long 
#SBATCH -c 4

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
echo "===== TAPS pipeline: Generating summary statistics of insert size distirbutions ====="
echo ""
echo "[check-insert-size]:       Validating arguments..."
if [[ ! -f $1 ]]
then
        echo "[check-insert-size]:       ERROR: Sample list file not found."
        exit 2
fi

if [[ ! -d $2 ]]
then
        echo "[check-insert-size]:       ERROR: Output directory not found."
        exit 2
fi 

echo "[check-insert-size]:       Reading sample list..."
readarray sampleList < $1
outDir=$2

## Loading required modules
echo "[check-insert-size]:		Loading modules..."
module load Java/11.0.2
module load picard/2.23.0-Java-11

# Per-task processing 
## Defining input and output names
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

echo "[check-insert-size]:       Checking insert size distirbution with picard ($sampleName)..."	
java -jar $EBROOTPICARD/picard.jar CollectInsertSizeMetrics \
	I="${sampleName}.qced.sorted.markdup.bam" \
	O="${outDir}/${sampleName}_insert_size_metrics.txt" \
	H="${outDir}/${sampleName}_insert_size_histogram.pdf" \
	M=0.5

echo "[check-insert-size]:       ...done!"	

