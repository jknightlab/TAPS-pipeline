# Load libraries
library(methylKit)
library(genomation)
library(GenomicRanges)

# Load data
## Methylation calls in methylKit format
meth_obj <- readRDS("./results/methylKit-R/methylKit-objects/SI-cfDNA_methylation-per-CpG_methylKit_mincov-1.rds")

## Annotations for Illumina 450K/EPIC array probes
Infinium_array_anns <- readGeneric(
  "/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/illumina-array-coordinates/Infinium-array_probe-annotations_all-gens-without-duplicates.bed",
  meta.cols = list(name=4)
  )

## Methylation tissue atlas published by Moss et al.
tissue_atlas_full <- read_csv("/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/methylation-atlases/Moss-et-al_2018/full_atlas.csv.gz")
tissue_atlas_reduced <- read_csv("/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/methylation-atlases/Moss-et-al_2018/reference_atlas.csv")

colnames(tissue_atlas_full)[1] <- "CpGs"

# Re-formatting data
## Removing Illumina probes with duplicated genomic coordinates
probe_coords <- data.frame(
  probe_id = Infinium_array_anns$name,
  coord = paste0(Infinium_array_anns@seqnames,":",Infinium_array_anns@ranges)
  )
probe_coords <- probe_coords[!duplicated(probe_coords$coord),]
Infinium_array_anns <- Infinium_array_anns[Infinium_array_anns$name %in% probe_coords$probe_id]

## Matching CpGs to their corresponding Illumina arrays probes
Infinium_meth <- meth_obj
for(i in 1:length(Infinium_meth)){
  Infinium_meth[[i]] <- regionCounts(Infinium_meth[[i]], Infinium_array_anns)
}
Infinium_meth <- methylKit::unite(Infinium_meth, destrand=TRUE, min.per.group = 1L)

## Extracting methylation proportions per CpG
Infinium_methyl_mat <- data.frame(
  percMethylation(Infinium_meth)/100, 
  row.names = paste0(Infinium_meth$chr, ":", Infinium_meth$start, "-", Infinium_meth$end)
    )

probe_coords <- data.frame(probe_coords, row.names = probe_coords$coord)
rownames(Infinium_methyl_mat) <- probe_coords[rownames(Infinium_methyl_mat),]$probe_id

## Assessing the coverage of CpGs in Moss et al. within our experiment
sum(tissue_atlas_reduced$CpGs %in% rownames(Infinium_methyl_mat))
sum(tissue_atlas_full$CpGs %in% rownames(Infinium_methyl_mat))

# Exporting results
## Writing as comma-separated file
write.csv(
  Infinium_methyl_mat, 
  "./results/methylKit-R/methylation-matrices/SI-cfDNA_methylation-percentage-per-CpG_matched-to-illumina-probes_mincov-1_full.csv",
  quote = F
  )

