#!/usr/bin/env bash
set -euo pipefail

FILE_PATH_SRC="/work/home/vivek/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/permutation_sequence_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb/dsmpl_3x/om_z_2d_ordinal_patterns_embed_dim_4_delay_1.h5"
FILE_PATH_TGT="/work/home/vivek/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/permutation_sequence_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb/dsmpl_3x/v_2d_ordinal_patterns_embed_dim_4_delay_1.h5"
DSET_PATH="/ds"
JAR_PATH="/work/home/vivek/000_datasets/infodynamics.jar"
OUT_DIR="/work/home/vivek/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/permutation_transfer_entropy_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb_lustre/om_z_2d_to_v_2d"

mpirun -np 48 --mca btl_openib_allow_ib true -machinefile $PBS_NODEFILE --oversubscribe vInfoFlow-mpi \
  --jar-path ${JAR_PATH} \
  --source-specs ${FILE_PATH_SRC}::${DSET_PATH} \
  --target-specs ${FILE_PATH_TGT}::${DSET_PATH} \
  --out-dir ${OUT_DIR} \
  --delay-start 1 \
  --delay-end 20 \
  --measure te \
  --backend jidt \
  --feature-axis 0 \
  --variable-type discrete \
  --checkpoint ${OUT_DIR}/checkpoint.json \
  --run-id te_202605141431

#vInfoFlow-merge \
#    --out-dir ${OUT_DIR} \
#    --output-file ${OUT_DIR}/pte_merged.h5 \
#    --checkpoint ${OUT_DIR}/checkpoint.json
