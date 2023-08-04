#!/usr/bin/bash

## Author:      Eddie Cano-Gamez (ecg@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J slide-windows

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/create-sliding-windows_%j.out 
#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/create-sliding-windows_%j.err 

#SBATCH -p short 
#SBATCH -c 2

# Outputing relevant information on how the job was run
echo "------------------------------------------------" 
echo "Run on host: "`hostname` 
echo "Operating system: "`uname -s` 
echo "Username: "`whoami` 
echo "Started at: "`date` 
echo "------------------------------------------------" 

## Reading in arguments
echo "===== Creating sliding windows around all TSS in the human genome ====="
echo ""

# Setting default parameter values
region_size=5000
window_size=120
step_size=1
output_dir=$PWD
gene_coords='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/cfDNA-methylation_04-2023/data/functional-annotations/gencode-v43_grch38.bed'

# Reading in arguments
while getopts ":r:w:s:o:" option; 
do
	case $option in
	r)
		region_size="$OPTARG"
		;;
	w)
		window_size="$OPTARG"
		;;
	s)
		step_size="$OPTARG"
		;;
	o)
		output_dir="$OPTARG"
		;;
	g)
		gene_coords="$OPTARG"
		;;
	*)
		echo "Usage: $0 [-r region_size] [-w window_size] [-s step_size] [-o output_dir] [-g gene_coords]"
		exit 1
		;;
	esac
done

echo "[slide-windows]:	Validating arguments..."
if [[ ! -f $gene_coords ]]
then
        echo "[slide-windows]:	ERROR: GENCODE transcript coordiantes file not found"
        exit 2
fi

if [[ ! -d $output_dir ]]
then
        echo "[slide-windows]:	ERROR: Output directory not found."
        exit 2
fi 

echo "[slide-windows]:	Parameter values will be as follows:"
echo "[slide-windows]:		- Region size: $(($region_size/1000)) kb"
echo "[slide-windows]:		- Sliding window size: $window_size bp"
echo "[slide-windows]:		- Sliding step size: $step_size bp"
echo "[slide-windows]:		- Gene coordiantes file: $gene_coords"
echo "[slide-windows]:		- Output directory: $output_dir"

# Creating sliding windows
echo "[slide-windows]:	Creating region file with $(($region_size/1000)) kb windows around each TSS..."
region_flank=$(($region_size/2))
cat $gene_coords | \
	awk '{print $1"\t"$2-'$region_flank'"\t"$2+'$region_flank'"\t"$4"\t"$6}' | \
	grep -v 'chrM' | \
	grep -v 'chr[0-9]_' | \
	grep -v 'chr[0-9][0-9]_' | \
	grep -v 'chr[X-Y]_' | \
	grep -v 'chrUn' \
	> "${output_dir}/TSS-region-file_$(($region_size/1000))kb.bed"

echo "[slide-windows]:	Sliding regions with a $window_size bp window and $step_size bp increments..."
/well/jknight/users/awo868/software/bedtools makewindows \
	-b "${output_dir}/TSS-region-file_$(($region_size/1000))kb.bed" \
	-w $window_size \
	-s $step_size \
	> "${output_dir}/sliding-windows-around-TSSs_k-120.bed"
	
echo "[slide-windows]:	...done!"

