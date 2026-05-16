#!/usr/bin/env python3
"""
Process permutation transfer entropy from a single h5 file containing multiple delay datasets.

This script finds the maximum value across all delay datasets for each element of the matrix,
and stores both the maximum values and the delay indices where they occur in separate datasets
within the same h5 file.
"""

import h5py
import numpy as np
import os
import re
from pathlib import Path


def find_max_across_delays_single_file(input_file, output_file=None):
    """
    Find maximum values across delay parameters and their corresponding delay indices
    from datasets within a single h5 file.
    
    Parameters
    ----------
    input_file : str
        Path to the input h5 file containing datasets named 'te/delay_{tau_value}'
    output_file : str, optional
        Path to save output file. If None, creates output next to input file
        with '_max_values_and_delays' appended to the stem.
    
    Returns
    -------
    max_values : np.ndarray
        Matrix containing maximum values across all delays
    max_delays : np.ndarray
        Matrix containing the delay values where maximum occurred
    
    Example
    -------
    >>> max_vals, max_taus = find_max_across_delays_single_file(
    ...     input_file='/scratch/asevivek/vivek_cases/.../pTE_om_z_2d_to_v_2d_dsmpl_3x.h5'
    ... )
    """

    if not os.path.exists(input_file):
        raise FileNotFoundError(f"Input file not found: {input_file}")

    # Set output file if not provided
    if output_file is None:
        input_path = Path(input_file)
        output_file = input_path.parent / f"{input_path.stem}_max_values_and_delays.h5"

    # Read the input file and identify tau datasets
    with h5py.File(input_file, 'r') as f:

        # Debug: show file structure
        print("Top-level keys in file:", list(f.keys()))
        if 'te' in f:
            print("Keys inside 'te' group:", list(f['te'].keys()))

        # Collect all delay datasets by walking the entire file tree
        tau_datasets = []

        def collect_delay_datasets(name, obj):
            if isinstance(obj, h5py.Dataset):
                match = re.search(r'delay_(\d+)$', name)
                if match:
                    tau_datasets.append((int(match.group(1)), name))

        f.visititems(collect_delay_datasets)

        if not tau_datasets:
            raise ValueError(
                f"No datasets matching pattern 'delay_*' found anywhere in {input_file}.\n"
                f"Top-level keys present: {list(f.keys())}"
            )

        # Sort by tau value
        tau_datasets.sort(key=lambda x: x[0])

        print(f"\nFound {len(tau_datasets)} delay datasets:")
        for tau, path in tau_datasets:
            print(f"  {path} (tau={tau})")

        # Get shape from first dataset
        first_path = tau_datasets[0][1]
        data_shape = f[first_path].shape
        print(f"\nMatrix shape: {data_shape}")

        # Initialize output arrays
        max_values = np.full(data_shape, -np.inf, dtype=np.float32)
        max_delays = np.zeros(data_shape, dtype=np.int32)

        # Process each delay dataset
        for tau, path in tau_datasets:
            print(f"Processing: {path} (tau={tau})")

            data = f[path][:]

            # Update maximum values and corresponding delays
            mask = data > max_values
            max_values[mask] = data[mask]
            max_delays[mask] = tau

    # Save results to output h5 file
    with h5py.File(output_file, 'w') as f:
        # Store maximum values
        f.create_dataset('max_values', data=max_values, compression='gzip', compression_opts=4)

        # Store delay values where maximum occurred
        f.create_dataset('max_delays', data=max_delays, compression='gzip', compression_opts=4)

        # Store metadata
        f.attrs['description'] = (
            'Maximum permutation transfer entropy across all delays '
            'and corresponding tau values'
        )
        f.attrs['source_file'] = os.path.basename(input_file)
        f.attrs['delays_processed'] = [tau for tau, _ in tau_datasets]
        f.attrs['num_delays'] = len(tau_datasets)

    print(f"\nOutput file created: {output_file}")
    print(f"\nSummary statistics:")
    print(f"  Max values - Min: {np.nanmin(max_values):.6e}, "
          f"Max: {np.nanmax(max_values):.6e}, "
          f"Mean: {np.nanmean(max_values):.6e}")
    print(f"  Delay distribution:")
    unique_delays, counts = np.unique(max_delays, return_counts=True)
    for delay, count in zip(unique_delays, counts):
        print(f"    tau={delay}: {count} elements ({100 * count / max_delays.size:.2f}%)")

    return max_values, max_delays


def main():
    """
    Main function - configure parameters here and run the processing.
    """

    # ------------------------------------------------------------------ #
    # Configuration parameters - MODIFY THESE
    # ------------------------------------------------------------------ #
    INPUT_FILE = (
        '/work/home/vivek/000_datasets/000/_toolbox_outputs/information_theory/'
        'permutation_related/permutation_transfer_entropy_computations/'
        'single_cylinder_Re7k_with_PGS_with_inflow_turb_lustre/'
        'v_2d_to_v_2d/pte_merged.h5'
    )

    OUTPUT_DIR = (
        '/work/home/vivek/000_datasets/000/_toolbox_outputs/information_theory/'
        'permutation_related/max_permutation_transfer_entropy_computations/'
        'single_cylinder_Re7k_with_PGS_with_inflow_turb_lustre'
    )

    OUTPUT_FILE_STEM = 'pTE_v_2d_to_v_2d_max_values_and_delays'
    # ------------------------------------------------------------------ #

    # Build full output path
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_file = os.path.join(OUTPUT_DIR, f"{OUTPUT_FILE_STEM}.h5")

    # Run the processing
    max_values, max_delays = find_max_across_delays_single_file(
        input_file=INPUT_FILE,
        output_file=output_file,
    )

    print("\nProcessing completed successfully!")


if __name__ == '__main__':
    main()
