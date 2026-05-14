#!/usr/bin/env bash
set -euo pipefail

FILE_PATH="/work/home/vivek/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/permutation_sequence_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb/dsmpl_3x/om_z_2d_ordinal_patterns_embed_dim_4_delay_1.h5"
DSET_PATH="/ds"
JAR_PATH="/work/home/vivek/000_datasets/infodynamics.jar"
OUT_DIR="/work/home/vivek/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/permutation_transfer_entropy_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb_lustre/om_z_2d_to_om_z_2d"

mpirun -np 48 --mca btl_openib_allow_ib true -machinefile $PBS_NODEFILE --oversubscribe vInfoFlow-mpi \
  --jar-path ${JAR_PATH} \
  --file-path ${FILE_PATH} \
  --dset-path ${DSET_PATH} \
  --out-dir ${OUT_DIR} \
  --delay-start 1 \
  --delay-end 20 \
  --measure te \
  --backend jidt \
  --feature-axis 0 \
  --variable-type discrete \
  --checkpoint ${OUT_DIR}/checkpoint.json \
  --run-id pTE_202605141429

#vInfoFlow-merge \
#    --out-dir ${OUT_DIR} \
#    --output-file ${OUT_DIR}/pte_merged.h5 \
#    --checkpoint ${OUT_DIR}/checkpoint.json
