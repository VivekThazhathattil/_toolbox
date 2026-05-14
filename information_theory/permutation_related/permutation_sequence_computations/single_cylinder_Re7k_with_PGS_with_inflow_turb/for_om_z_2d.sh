#!/usr/bin/env bash
set -euo pipefail

# Example: convert a feature-by-time HDF5 dataset into ordinal-pattern tokens
INPUT_FILE="/scratch/asevivek/vivek_cases/000_datasets/001_single_cylinder_case_single_plane_spanwise_averaged_velocity_and_vorticitcy_fields/om_z_2d_dsmpl_3x.h5"
INPUT_DSET="/ds"
OUTPUT_FILE="/scratch/asevivek/vivek_cases/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/permutation_sequence_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb/dsmpl_3x/om_z_2d_ordinal_patterns_embed_dim_4_delay_1.h5"
OUTPUT_DSET="/ds"

vInfoFlow-ordinal-patterns \
  --input-file "${INPUT_FILE}" \
  --input-dset "${INPUT_DSET}" \
  --output-file "${OUTPUT_FILE}" \
  --output-dset "${OUTPUT_DSET}" \
  --embedding-dim 4 \
  --delay 1 \
  --feature-axis 0 \
  --nan-fill-value 0.0

