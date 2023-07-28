# Identity check of sequencing files

Author:		Eddie Cano-Gamez

Email:		ecg@well.ox.ac.uk


## Overview

This directory contains codes to perform identity checks and verify if any sample swaps exists based on genotypes inferred from sequencing data files.

These codes are based on Picard's CrosscheckFingerprints functionality and based on a previous set of codes written by Dr Ping Zhang (see https://github.com/jknightlab/Sample-identity-CHECK)


## Repository structure

The codes contained within this repository are written in bash and ordered as follows:

```
./
 |-- 1_add-read-groups.sh		Adds read group information to each BAM file, where read groups reflect sample ids.
 `-- 2_crosscheck-fingerprints.sh	Merges all BAM files into a single master file and applies fingerprint crosschecking to verify if different read groups originate from the same genotype.
```

