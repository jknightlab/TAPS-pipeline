#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/sort-and-markdup_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/sort-and-markdup_%j.err 
#SBATCH -p long 
#SBATCH -c 6

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
echo "===== TAPS pipeline step 3: Read sorting, filtering, and duplicate marking ====="
echo ""
echo "[sort-and-markdup]:	Validating arguments..."
if [[ ! -f $1 ]]
then
	echo "[sort-and-markdup]:	ERROR: Sample list file not found."
	exit 2
fi

if [[ ! -d $2 ]]
then
	echo "[sort-and-markdup]:	ERROR: Output directory not found."
	exit 2
fi 

echo "[sort-and-markdup]:	Reading sample list..."
readarray sampleList < $1
outDir=$2

## Loading BWA module
echo "[sort-and-markdup]:	Loading modules..."
module load Java/11.0.2
module load samtools/1.8-gcc5.4.0
module load picard/2.23.0-Java-11

# Per-task processing 
## Defining input and output names
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

## Running BWA
echo "[sort-and-markdup]: Filtering and sorting $sampleName alignment..."

if [[ ! -d tmp ]]
then
	mkdir tmp
fi

samtools view -h -q 10 "${sampleName}.sam" | \
	samtools sort -@ 10 -O bam > "./tmp/${sampleName}.bam"


echo "[sort-and-markdup]: Marking read duplicates..."

java -jar $EBROOTPICARD/picard.jar MarkDuplicates \
	I="./tmp/${sampleName}.bam" \
	O="${outDir}/${sampleName}.qced.sorted.markdup.bam" \
	M="${outDir}/${sampleName}_marked_dup_metrics.txt" 


echo "[sort-and-markdup]: Cleaning up..."

rm "./tmp/${sampleName}.bam"


echo "[sort-and-markdup]: ...done!"
