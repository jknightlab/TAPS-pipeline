#!/usr/bin/bash

# Loading modules
module load Kraken2/2.1.3-gompi-2023a

# Setting up
mkdir kraken2-db

# Building Kraken2 database
## Downloading taxonomy (requires internet access)
kraken2-build --download-taxonomy --db ./kraken2-db

## Downloading libraries (requires internet access)
kraken2-build --download-library archaea --db ./kraken2-db
kraken2-build --download-library bacteria --db ./kraken2-db
kraken2-build --download-library viral --db ./kraken2-db
kraken2-build --download-library plasmid --db ./kraken2-db
kraken2-build --download-library human --db ./kraken2-db
kraken2-build --download-library UniVec_Core --db ./kraken2-db
kraken2-build --download-library protozoa --db ./kraken2-db
kraken2-build --download-library fungi --db ./kraken2-db

## Building database (to be done from within a computing node)
kraken2-build --build --db ./kraken2-db --threads 12

## Cleaning up
kraken2-build --clean --db ./kraken2-db
