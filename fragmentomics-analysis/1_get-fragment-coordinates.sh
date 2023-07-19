#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J fragment-coords

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/get-fragment-coordinates_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/get-fragment-coordinates_%j.err 

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
echo "===== Fragmentomics pipeline: Obtaining mapping coordinates for cfDNA fragments ====="
echo ""
echo "[fragment-coordinates]:	Validating arguments..."
if [[ ! -f $1 ]]
then
        echo "[fragment-coordinates]:	ERROR: Sample list not found."
        exit 2
fi

if [[ ! -d $2 ]]
then
        echo "[fragment-coordinates]:	ERROR: Output directory not found."
        exit 2
fi 

## Loading required modules and files
echo "[fragment-coordinates]:	Loading modules..."
module load samtools/1.8-gcc5.4.0

echo "[fragment-coordinates]:	Reading sample list..."
readarray sampleList < $1
outDir=$2

# Per-task processing 
## Defining input names
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

## Retrieving coordinates
echo "[fragment-coordinates]:	Fetching fragment coordinates from BAM file ($sampleName)..."
samtools view -F 3100 -f 3 -q 10 \
	"${sampleName}.qced.sorted.markdup.bam" | \
	cut -f 1,3,4,9 | \
	awk '{print $2"\t"$3-1"\t"$3-1+$4,"\t"$1}' \
	> "${outDir}/${sampleName}_fragment-coordinates.bed"

echo "[fragment-coordinates]:	...done!"
