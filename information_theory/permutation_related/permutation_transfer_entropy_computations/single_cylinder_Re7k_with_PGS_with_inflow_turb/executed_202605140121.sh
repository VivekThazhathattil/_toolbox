#!/bin/bash

BINARY="/scratch/asevivek/vBatchDiscreteTransferEntropy/build/transfer_entropy"
SOURCE_INPUT="/scratch/asevivek/vivek_cases/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/permutation_sequence_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb/dsmpl_3x/om_z_2d_ordinal_patterns_embed_dim_4_delay_1.h5"
TARGET_INPUT="/scratch/asevivek/vivek_cases/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/permutation_sequence_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb/dsmpl_3x/v_2d_ordinal_patterns_embed_dim_4_delay_1.h5"
OUTPUT="/scratch/asevivek/vivek_cases/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/permutation_transfer_entropy_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb/pTE_om_z_2d_to_v_2d_dsmpl_3x.h5"
SOURCE_ALPHABET=24
TARGET_ALPHABET=24

# Check if binary exists
if [ ! -f "$BINARY" ]; then
    echo "Error: Binary not found at $BINARY"
    exit 1
fi

echo "--- Computing TE with different alphabet sizes ---"
"$BINARY" \
    --source-input-file "$SOURCE_INPUT" \
    --target-input-file "$TARGET_INPUT" \
    --output "$OUTPUT" \
    --source-alphabet-size "$SOURCE_ALPHABET" \
    --target-alphabet-size "$TARGET_ALPHABET" \
    --tau-beg 1 \
    --tau-end 10 \
    --source-dataset-path /ds \
    --target-dataset-path /ds \
    --output-dataset /ds \
    --log-base bits \
    --separate-files

echo "--- Results saved to $OUTPUT ---"
h5ls "$OUTPUT"
