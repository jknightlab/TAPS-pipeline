#!/usr/bin/bash

## Author:	Kiki Cano-Gamez (kiki.canogamez@well.ox.ac.uk)

##########################################################################################
# Specifying Slurm parameters for job submission
#SBATCH -A jknight.prj 
#SBATCH -J bigwig

#SBATCH -o /well/jknight/users/awo868/logs/TAPS-pipeline/make-bigwig_%j.out 

#SBATCH -e /well/jknight/users/awo868/logs/TAPS-pipeline/make-bigwig_%j.err 
#SBATCH -p long 
#SBATCH -c 4
##########################################################################################

# Setting default parameter values
input_dir=$PWD
output_dir=$PWD
chrom_sizes_path='/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/chromsizes/GRCh38-reference_with-spike-in-sequences.chrom.sizes'

# Reading in arguments
while getopts i:o:s:c:h opt
do
	case $opt in
	i)
		input_dir=$OPTARG
		;;
	o)
		output_dir=$OPTARG
		;;
	s)
		sample_list_path=$OPTARG
		;;
	c)
		chrom_sizes_path=$OPTARG
		;;
	h)
		echo "Usage:	make-bigwig.sh [-i input_dir] [-o output_dir] [-s sample_list_path] [-c chrom_sizes_path]"
		echo ""
		echo "Where:"
		echo "-i		Path to input directory containing bedGraph files with methylation calls [defaults to the working directory]"
		echo "-o		Path to output directory where to store compressed bigwig files for visualisation [defaults to the working directory]"
		echo "-s		Path to a text file containing a list of samples (one sample per line). Sample names should match file naming patterns."
		echo "-c		Path to a chromsome sizes file (chrom.sizes) for the reference genome used for alignment. [defaults to a pre-computed chrom.szies file built from GRCh38]"
		echo ""
		exit 1
		;;
	esac
done

# Validating arguments
echo "[mapping-stats]:	Validating arguments..."

if [[ ! -d $input_dir ]]
then
		echo "[mapping-stats]:	ERROR: Input directory not found."
		exit 2
fi 

if [[ ! -d $output_dir ]]
then
		echo "[mapping-stats]:	ERROR: Output directory not found."
        exit 2
fi 

if [[ ! -f $sample_list_path ]]
then
        echo "[mapping-stats]:	ERROR: Sample list file not found"
        exit 2
fi

# Outputing relevant information on how the job was run
echo "------------------------------------------------" 
echo "Run on host: "`hostname` 
echo "Operating system: "`uname -s` 
echo "Username: "`whoami` 
echo "Started at: "`date` 
echo "Executing task ${SLURM_ARRAY_TASK_ID} of job ${SLURM_ARRAY_JOB_ID} "
echo "------------------------------------------------" 

# Parsing input file
echo "[mapping-stats]:       Reading sample list..."
readarray sampleList < $sample_list_path

#  Parallelising process by sample
sampleName=$(echo ${sampleList[$((${SLURM_ARRAY_TASK_ID}-1))]} | sed 's/\n//g')
echo "[mapping-stats]:       Processing sample $sampleName..."	

echo "[make-bigwig]:       Running bigWig conversion for sample ${sampleName}..."
## Running command
if [[ ! -d "${output_dir}/tmp" ]]
then
        mkdir "${output_dir}/tmp"
fi

echo "[make-bigwig]:       Reformatting bedGraph to match TAPS chemistry..."
cat "${input_dir}/${sampleName}_CpG.bedGraph" | \
	tail -n +2 | \
	awk '{print $1"\t"$2"\t"$3"\t"100-$4}' > "${output_dir}/tmp/${sampleName}_CpG.tmp.bedGraph"

echo "[make-bigwig]:       Sorting bedGraph..."	
/well/jknight/users/awo868/software/ucsc/bedSort \
	"${output_dir}/tmp/${sampleName}_CpG.tmp.bedGraph" \
	"${output_dir}/tmp/${sampleName}_CpG.tmp.sorted.bedGraph"

echo "[make-bigwig]:       Creating bigWig file..."	
/well/jknight/users/awo868/software/ucsc/bedGraphToBigWig \
	"${output_dir}/tmp/${sampleName}_CpG.tmp.sorted.bedGraph" \
	$chrom_sizes_path \
	"${output_dir}/${sampleName}_CpG.flipped.bw"

echo "[make-bigwig]:       Cleaning up..."	
rm "${output_dir}/tmp/${sampleName}_CpG.tmp.bedGraph" "${output_dir}/tmp/${sampleName}_CpG.tmp.sorted.bedGraph"

echo "[make-bigwig]:       ...done!"
