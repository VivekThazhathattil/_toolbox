#!/usr/bin/env python3
"""
Process permutation transfer entropy files across different delay parameters.

This script finds the maximum value across all delays for each element of the matrix,
and stores both the maximum values and the delay indices where they occur in separate h5 files.
"""

import h5py
import numpy as np
import os
import glob
import re
from pathlib import Path


def find_max_across_delays(input_dir, file_prefix, dataset_name='ds', output_dir=None):
    """
    Find maximum values across delay parameters and their corresponding delay indices.
    
    Parameters
    ----------
    input_dir : str
        Directory containing the input h5 files
    file_prefix : str
        Prefix of files to process (e.g., 'pTE_om_z_2d_to_v_2d_dsmpl_3x')
        Files should be named as {file_prefix}_tau_{tau_value}.h5
    dataset_name : str, optional
        Name of the dataset within each h5 file (default: 'ds')
    output_dir : str, optional
        Directory to save output files. If None, uses input_dir
    
    Returns
    -------
    max_values : np.ndarray
        Matrix containing maximum values across all delays
    max_delays : np.ndarray
        Matrix containing the delay values where maximum occurred
    
    Example
    -------
    >>> max_vals, max_taus = find_max_across_delays(
    ...     input_dir='/scratch/asevivek/vivek_cases/000_datasets/000/_toolbox_outputs/...',
    ...     file_prefix='pTE_om_z_2d_to_v_2d_dsmpl_3x'
    ... )
    """
    
    # Set output directory
    if output_dir is None:
        output_dir = input_dir
    
    # Find all matching files
    pattern = os.path.join(input_dir, f'{file_prefix}_tau_*.h5')
    h5_files = sorted(glob.glob(pattern))
    
    if not h5_files:
        raise FileNotFoundError(f"No files matching pattern: {pattern}")
    
    print(f"Found {len(h5_files)} files matching pattern")
    
    # Extract delay values from filenames
    delay_values = []
    for filepath in h5_files:
        # Extract tau value from filename (e.g., 'tau_10' -> 10)
        match = re.search(r'tau_(\d+)', os.path.basename(filepath))
        if match:
            tau = int(match.group(1))
            delay_values.append(tau)
        else:
            raise ValueError(f"Could not extract tau value from: {filepath}")
    
    # Sort files by delay value
    sorted_indices = np.argsort(delay_values)
    h5_files = [h5_files[i] for i in sorted_indices]
    delay_values = [delay_values[i] for i in sorted_indices]
    
    print(f"Delay values found: {delay_values}")
    
    # Load first file to determine shape
    with h5py.File(h5_files[0], 'r') as f:
        data_shape = f[dataset_name].shape
        print(f"Matrix shape: {data_shape}")
    
    # Initialize output arrays
    max_values = np.full(data_shape, -np.inf, dtype=np.float32)
    max_delays = np.zeros(data_shape, dtype=np.int32)
    
    # Process each file
    for filepath, tau in zip(h5_files, delay_values):
        print(f"Processing: {os.path.basename(filepath)} (tau={tau})")
        
        with h5py.File(filepath, 'r') as f:
            data = f[dataset_name][:]
        
        # Update maximum values and corresponding delays
        mask = data > max_values
        max_values[mask] = data[mask]
        max_delays[mask] = tau
    
    # Save results to h5 files
    output_max_file = os.path.join(output_dir, f'{file_prefix}_max_values.h5')
    output_delays_file = os.path.join(output_dir, f'{file_prefix}_max_delays.h5')
    
    with h5py.File(output_max_file, 'w') as f:
        f.create_dataset('ds', data=max_values, compression='gzip', compression_opts=4)
        f.attrs['description'] = 'Maximum permutation transfer entropy across all delays'
        f.attrs['delays_used'] = delay_values
    
    with h5py.File(output_delays_file, 'w') as f:
        f.create_dataset('ds', data=max_delays, compression='gzip', compression_opts=4)
        f.attrs['description'] = 'Delay value (tau) at which maximum occurred'
        f.attrs['delays_used'] = delay_values
    
    print(f"\nOutput files created:")
    print(f"  Max values: {output_max_file}")
    print(f"  Max delays: {output_delays_file}")
    print(f"\nSummary statistics:")
    print(f"  Max values - Min: {np.nanmin(max_values):.6e}, Max: {np.nanmax(max_values):.6e}, Mean: {np.nanmean(max_values):.6e}")
    print(f"  Delay distribution:")
    unique_delays, counts = np.unique(max_delays, return_counts=True)
    for delay, count in zip(unique_delays, counts):
        print(f"    tau={delay}: {count} elements")
    
    return max_values, max_delays


def main():
    """
    Main function - configure parameters here and run the processing.
    """
    
    # Configuration parameters - MODIFY THESE
    INPUT_DIR = '/scratch/asevivek/vivek_cases/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/permutation_transfer_entropy_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb'
    FILE_PREFIX = 'pTE_om_z_2d_to_v_2d_dsmpl_3x'
    #FILE_PREFIX = 'pTE_v_2d_to_om_z_2d_dsmpl_3x'
    DATASET_NAME = 'ds'
    #OUTPUT_DIR = INPUT_DIR  # Save outputs in the same directory
    OUTPUT_DIR = '/scratch/asevivek/vivek_cases/000_datasets/000/_toolbox_outputs/information_theory/permutation_related/max_permutation_transfer_entropy_computations/single_cylinder_Re7k_with_PGS_with_inflow_turb'
    
    # Run the processing
    max_values, max_delays = find_max_across_delays(
        input_dir=INPUT_DIR,
        file_prefix=FILE_PREFIX,
        dataset_name=DATASET_NAME,
        output_dir=OUTPUT_DIR
    )
    
    print("\nProcessing completed successfully!")


if __name__ == '__main__':
    main()
