# Load libraries
library(tidyverse)
library(limma)
library(pheatmap)
library(matrixStats)

# Load data
tissue_atlas_full <- read_csv("/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/methylation-atlases/Moss-et-al_2018/full_atlas.csv.gz")
tissue_atlas_reduced <- read_csv("./well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/methylation-atlases/Moss-et-al_2018/reference_atlas.csv")
Infinium_methyl_mat <- read_csv("./results/methylKit-R/methylation-matrices/SI-cfDNA_methylation-percentage-per-CpG_matched-to-illumina-probes_mincov-1.csv")

colnames(tissue_atlas_full)[1] <- "CpGs"

# Visualising
pheatmap(tissue_atlas_reduced[tissue_atlas_reduced$CpGs %in% Infinium_methyl_mat$CpGs,-1], scale="row", show_rownames = F)

pca_res <- prcomp(t(tissue_atlas_reduced[tissue_atlas_reduced$CpGs %in% Infinium_methyl_mat$CpGs,-1]))
pca_coords <- data.frame(tissue=rownames(pca_res$x), pca_res$x)
pc_vars <- pca_res$sdev^2/sum(pca_res$sdev^2)*100

plot(pc_vars, type="b")
ggplot(pca_coords, aes(x=PC1, y=PC2)) +
  geom_point() +
  geom_label_repel(aes(label=tissue)) +
  theme_classic()

plot(
  hclust(
    dist(
      t(tissue_atlas_reduced[tissue_atlas_reduced$CpGs %in% Infinium_methyl_mat$CpGs,-1])
      )
    )
  )

# Performing batch correction to remove differences between the blood cell types study by Salas et al. (GSE110555; EPIC array) and the remaining atlas (450K + EPIC array combination)
tissue_atlas_BC <- tibble(
  data.frame(
    CpGs = tissue_atlas_reduced$CpGs,
    limma::removeBatchEffect(
      x = as.matrix(tissue_atlas_reduced[,-1]), 
      batch = grepl("EPIC",colnames(tissue_atlas_reduced[,-1]))*1
      )
    )
  )

# Visualising batch-corrected atlas
pheatmap(tissue_atlas_BC[tissue_atlas_BC$CpGs %in% Infinium_methyl_mat$CpGs,-1], show_rownames = F, scale = "row")
plot(
  hclust(
    dist(
      t(tissue_atlas_BC[tissue_atlas_BC$CpGs %in% Infinium_methyl_mat$CpGs,-1])
    )
  )
)

pca_res <- prcomp(t(tissue_atlas_BC[tissue_atlas_BC$CpGs %in% Infinium_methyl_mat$CpGs,-1]))
pca_coords <- data.frame(tissue=rownames(pca_res$x), pca_res$x)
pc_vars <- pca_res$sdev^2/sum(pca_res$sdev^2)*100

plot(pc_vars, type="b")

ggplot(pca_coords, aes(x=PC1, y=PC2)) +
  geom_point() +
  geom_label_repel(aes(label=tissue)) +
  theme_classic()

# Exporting corrected atlas as CSV file
write.table(tissue_atlas_BC, "/well/jknight/projects/sepsis-immunomics/cfDNA-methylation/TAPS/resources/methylation-atlases/Moss-et-al_2018/reference_atlas_batch-corrected.csv", row.names = F, quote = F, sep=",")
