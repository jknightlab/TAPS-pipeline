#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/check-identity-1_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/check-identity-1_%j.err 

#SBATCH -p short 
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
echo "===== TAPS pipeline: Checking sample identity with Picard (1) ====="
echo ""
echo "[check-identity]:		Validating arguments..."
if [[ ! -f $1 ]]
then
        echo "[check-identity]:		ERROR: Sample list file not found."
        exit 2
fi

if [[ ! -d $2 ]]
then
        echo "[check-identity]:		ERROR: Output directory not found."
        exit 2
fi 

echo "[check-identity]:		Reading sample list..."
readarray sampleList < $1
outDir=$2

## Loading required modules
echo "[check-identity]:		Loading modules..."
module load Java/11.0.2
module load picard/2.23.0-Java-11

## Creating output directories
if [[ ! -d "${outDir}/tmp" ]]
then
        mkdir "${outDir}/tmp"
fi

# Per-task processing 
## Defining input and output names

sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')
echo "[check-identity]:       Processing sample $sampleName..."	

echo "[check-identity]:		Adding readgroups to BAM file..."	
java -jar $EBROOTPICARD/picard.jar AddOrReplaceReadGroups \
	I="${sampleName}.qced.sorted.markdup.bam" \
    O="${outDir}/tmp/${sampleName}.qced.sorted.markdup.RG.bam" \
    RGID="${sampleName}" \
    RGLB="TAPS" \
    RGPL="ILLUMINA" \
    RGPU="${sampleName}" \
    RGSM="${sampleName}"

echo "[check-identity]:		...done!"	

