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
        Path to the input h5 file containing datasets named 'ds_tau_{tau_value}'
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
        # Find all datasets matching pattern 'ds_tau_*'
        tau_datasets = []
        for key in sorted(f.keys()):
            match = re.match(r'ds_tau_(\d+)', key)
            if match:
                tau = int(match.group(1))
                tau_datasets.append((tau, key))
        
        if not tau_datasets:
            raise ValueError(f"No datasets matching pattern 'ds_tau_*' found in {input_file}")
        
        # Sort by tau value
        tau_datasets.sort(key=lambda x: x[0])
        
        print(f"Found {len(tau_datasets)} delay datasets:")
        for tau, key in tau_datasets:
            print(f"  {key} (tau={tau})")
        
        # Get shape from first dataset
        first_key = tau_datasets[0][1]
        data_shape = f[first_key].shape
        print(f"\nMatrix shape: {data_shape}")
        
        # Initialize output arrays
        max_values = np.full(data_shape, -np.inf, dtype=np.float32)
        max_delays = np.zeros(data_shape, dtype=np.int32)
        
        # Process each delay dataset
        for tau, key in tau_datasets:
            print(f"Processing: {key} (tau={tau})")
            
            data = f[key][:]
            
            # Update maximum values and corresponding delays
            mask = data > max_values
            max_values[mask] = data[mask]
            max_delays[mask] = tau
    
    # Save results to a new h5 file
    with h5py.File(output_file, 'w') as f:
        # Store maximum values
        f.create_dataset('max_values', data=max_values, compression='gzip', compression_opts=4)
        
        # Store delay values where maximum occurred
        f.create_dataset('max_delays', data=max_delays, compression='gzip', compression_opts=4)
        
        # Store metadata
        f.attrs['description'] = 'Maximum permutation transfer entropy across all delays and corresponding tau values'
        f.attrs['source_file'] = os.path.basename(input_file)
        f.attrs['delays_processed'] = [tau for tau, _ in tau_datasets]
        f.attrs['num_delays'] = len(tau_datasets)
    
    print(f"\nOutput file created: {output_file}")
    print(f"\nSummary statistics:")
    print(f"  Max values - Min: {np.nanmin(max_values):.6e}, Max: {np.nanmax(max_values):.6e}, Mean: {np.nanmean(max_values):.6e}")
    print(f"  Delay distribution:")
    unique_delays, counts = np.unique(max_delays, return_counts=True)
    for delay, count in zip(unique_delays, counts):
        print(f"    tau={delay}: {count} elements ({100*count/max_delays.size:.2f}%)")
    
    return max_values, max_delays


def main():
    """
    Main function - configure parameters here and run the processing.
    """
    
    # Configuration parameters - MODIFY THESE
    INPUT_FILE = '/work/home/vivek/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/permutation_transfer_entropy_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb_lustre/v_2d_to_v_2d/pte_merged.h5'
    OUTPUT_FILE = pTE_v_2d_to_v_2d_max_values_and_delays # If None, will create output file next to input with '_max_values_and_delays' suffix
    
    # Alternatively, you can specify an explicit output file:
    # OUTPUT_FILE = '/path/to/output/pTE_om_z_2d_to_v_2d_dsmpl_3x_max_values_and_delays.h5'
    OUTPUT_DIR = '/work/home/vivek/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/max_permutation_transfer_entropy_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb_lustre'
    
    # Run the processing
    max_values, max_delays = find_max_across_delays_single_file(
        input_file=INPUT_FILE,
        output_file=OUTPUT_FILE
    )
    
    print("\nProcessing completed successfully!")


if __name__ == '__main__':
    main()
