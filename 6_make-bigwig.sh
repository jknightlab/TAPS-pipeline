#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/make-bigwig_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/make-bigwig_%j.err 
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
echo "===== TAPS pipeline step 6: Generating bigWig files for visualisation ====="
echo ""
echo "[make-bigWig]:       Validating arguments..."
if [[ ! -f $1 ]]
then
        echo "[make-bigwig]:       ERROR: Sample list file not found."
        exit 2
fi

if [[ ! -d $2 ]]
then
        echo "[make-bigwig]:       ERROR: Output directory not found."
        exit 2
fi 

echo "[make-bigwig]:       Reading sample list..."
readarray sampleList < $1
outDir=$2

# Per-task processing 
## Defining input and output names
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')
chromSizesFile='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/results/TAPS-pipeline/methyl-dackel/reference-genome/GRCh38-reference_with-spike-in-sequences.chrom.sizes'

echo "[make-bigwig]:       Running bigWig conversion for sample ${sampleName}..."
## Running command
if [[ ! -d tmp ]]
then
        mkdir tmp
fi

echo "[make-bigwig]:       Reformatting bedGraph to match TAPS chemistry..."
cat "${sampleName}_CpG.bedGraph" | \
	tail -n +2 | \
	awk '{print $1"\t"$2"\t"$3"\t"100-$4}' > "./tmp/${sampleName}_CpG.tmp.bedGraph"

echo "[make-bigwig]:       Sorting bedGraph..."	
/well/jknight/users/awo868/software/ucsc/bedSort \
	"./tmp/${sampleName}_CpG.tmp.bedGraph" \
	"./tmp/${sampleName}_CpG.tmp.sorted.bedGraph"

echo "[make-bigwig]:       Creating bigWig file..."	
/well/jknight/users/awo868/software/ucsc/bedGraphToBigWig \
	"./tmp/${sampleName}_CpG.tmp.sorted.bedGraph" \
	$chromSizesFile \
	"${outDir}/${sampleName}_CpG.bw"

echo "[make-bigwig]:       Cleaning up..."	
rm "./tmp/${sampleName}_CpG.tmp.bedGraph" "./tmp/${sampleName}_CpG.tmp.sorted.bedGraph"

echo "[make-bigwig]:       ...done!"	

