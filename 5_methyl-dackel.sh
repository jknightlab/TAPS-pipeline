#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/methyl-dackel_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/methyl-dackel_%j.err 
#SBATCH -p long 
#SBATCH -c 8

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
echo "===== TAPS pipeline step 5: Methylation calling with MethylDackel ====="
echo ""
echo "[methyl-dackel]:	Validating arguments..."
if [[ ! -f $1 ]]
then
	echo "[methyl-dackel]:	ERROR: Sample list file not found."
	exit 2
fi

if [[ ! -d $2 ]]
then
	echo "[methyl-dackel]:	ERROR: Output directory not found."
	exit 2
fi 

echo "[methyl-dackel]:	Reading sample list..."
readarray sampleList < $1
outDir=$2

## Loading required modules and virtual environments
echo "[methyl-dackel]:	Loading required modules..."
module load Anaconda3/2022.05

echo "[methyl-dackel]:	Loading virtual environment..."
eval "$(conda shell.bash hook)"
conda activate methylDackel

## Defining path variables
referenceGenome='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/results/TAPS-pipeline/methyl-dackel/reference-genome/GRCh38-reference_with-spike-in-sequences.fasta.gz'

# Per-task processing 
## Defining input and output names
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')

## Running MethylDackel
echo "[methyl-dackel]:	Calling methylation events with MethylDackel ($sampleName)..."
MethylDackel extract \
	-q 10 \
	-p 10 \
	-t 4 \
	--mergeContext \
	-o "${outDir}/${sampleName}" \
	--OT 5,135,5,115 \
	--OB 20,145,35,145 \
	$referenceGenome \
	"${sampleName}.qced.sorted.markdup.bam"

echo "[methyl-dackel]: ...done!"
