#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/get-mapping-stats_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/get-mapping-stats_%j.err 

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
echo "===== TAPS pipeline: Generating read mapping statistics based on BWA MEM outputs ====="
echo ""
echo "[mapping-stats]:       Validating arguments..."
if [[ ! -f $1 ]]
then
        echo "[mapping-stats]:       ERROR: Sample list file not found."
        exit 2
fi

if [[ ! -d $2 ]]
then
        echo "[mapping-stats]:       ERROR: Output directory not found."
        exit 2
fi 

echo "[mapping-stats]:       Reading sample list..."
readarray sampleList < $1
outDir=$2

## Loading required modules
echo "[mapping-stats]:	Loading modules..."
module load Java/11.0.2
module load picard/2.23.0-Java-11
module load samtools/1.8-gcc5.4.0

## Creating output directories
echo "[mapping-stats]:	Setting up output directory structure..."
if [[ ! -d "${outDir}/mapping-stats" ]]
then
        mkdir "${outDir}/mapping-stats"
fi

if [[ ! -d "${outDir}/insert-sizes" ]]
then
        mkdir "${outDir}/insert-sizes"
fi

if [[ ! -d "${outDir}/genome-coverage" ]]
then
        mkdir "${outDir}/genome-coverage"
fi


# Per-task processing 
## Defining input and output names
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')
echo "[mapping-stats]:       Processing sample $sampleName..."	

echo "[mapping-stats]:       Computing mapping statistics with samtools..."	
samtools stats -d "${sampleName}.qced.sorted.markdup.bam" > "${outDir}/mapping-stats/${sampleName}_mapping-statistics.txt"


echo "[mapping-stats]:       Checking insert size distirbution with picard..."	
java -jar $EBROOTPICARD/picard.jar CollectInsertSizeMetrics \
	I="${sampleName}.qced.sorted.markdup.bam" \
    O="${outDir}/insert-sizes/${sampleName}_insert_size_metrics.txt" \
    H="${outDir}/insert-sizes/${sampleName}_insert_size_histogram.pdf" \
    M=0.5

echo "[mapping-stats]:       Computing genome coverage with BEDtools..."	
/well/jknight/users/awo868/software/bedtools genomecov \
	-ibam "${sampleName}.qced.sorted.markdup.bam" \
	> "${outDir}/genome-coverage/${sampleName}_genome-coverage.txt"

echo "[mapping-stats]:       ...done!"	

