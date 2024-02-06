#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/deconvolute-array-methylomes_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/deconvolute-array-methylomes_%j.err 

#SBATCH -p short 
#SBATCH -c 4

# Outputing relevant information on how the job was run
echo "------------------------------------------------" 
echo "Run on host: "`hostname` 
echo "Operating system: "`uname -s` 
echo "Username: "`whoami` 
echo "Started at: "`date` 
echo "------------------------------------------------" 


##########################################################################################
# Reading in arguments
echo "===== Tissue deconvolution pipeline: Deconvolute methylation calls into tissue contributions ====="
echo ""
echo "[deconvolute-methylomes]:	Validating arguments..."
if [[ ! -f $1 ]]
then
        echo "[deconvolute-methylomes]:	ERROR: Input file not found."
        exit 2
fi

if [[ ! -f $2 ]]
then
        echo "[deconvolute-methylomes]:	ERROR: Tissue atlas file not found."
        exit 2
fi

if [[ ! -d $3 ]]
then
        echo "[deconvolute-methylomes]: ERROR: Output directory not found."
        exit 2
fi 

# Loading required modules and files
echo "[deconvolute-methylomes]:	Loading virtual environment..."
module load Anaconda3/2022.05
eval "$(conda shell.bash hook)"
conda activate wgbstools

# Getting path to reference tissue atlas
inputFile=$1
referenceAtlas=$2
outDir=$3

deconvolvePath='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/methylation-atlases/Moss-et-al_2018/deconvolve.py'

# Deconvoluting data
echo "[deconvolute-methylomes]:	Running deconvolution analysis..."
python $deconvolvePath \
	--atlas_path $referenceAtlas \
	--out_dir $outDir \
	$inputFile

echo "[deconvolute-methylomes]:	...done!"

