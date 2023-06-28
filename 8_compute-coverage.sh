#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/compute-coverage_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/compute-coverage_%j.err 

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
echo "===== TAPS pipeline: Computing genome coverage statistics ====="
echo ""
echo "[compute-coverage]:       Validating arguments..."
if [[ ! -f $1 ]]
then
        echo "[compute-coverage]:       ERROR: Sample list file not found."
        exit 2
fi

if [[ ! -d $2 ]]
then
        echo "[compute-coverage]:       ERROR: Output directory not found."
        exit 2
fi 

echo "[compute-coverage]:       Reading sample list..."
readarray sampleList < $1
outDir=$2

# Per-task processing 
## Defining input and output names
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

echo "[compute-coverage]:       Computing genome coverage with BEDtools ($sampleName)..."	
/well/jknight/users/awo868/software/bedtools genomecov \
	-ibam "${sampleName}.qced.sorted.markdup.bam" \
	> "${outDir}/${sampleName}_genome-coverage.txt"
	
echo "[compute-coverage]:       ...done!"	

