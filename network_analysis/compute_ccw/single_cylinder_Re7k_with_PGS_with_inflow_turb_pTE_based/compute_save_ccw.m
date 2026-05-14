clear; clc; close all;

path_to_add="/scratch/asevivek/vInfoTheory/infoflow/scripts/matlab";

te_mat_file="/scratch/asevivek/vivek_cases/000_datasets/000/_toolbox_outputs/" + ...
    "information_theory/permutation_related/max_permutation_transfer_entropy_computations/" + ...
    "single_cylinder_Re7k_with_PGS_with_inflow_turb/pTE_om_z_2d_to_v_2d_dsmpl_3x_max_values.h5";

% te_mat_file="/scratch/asevivek/vivek_cases/000_datasets/000/_toolbox_outputs/" + ...
%     "information_theory/permutation_related/max_permutation_transfer_entropy_computations/" + ...
%     "single_cylinder_Re7k_with_PGS_with_inflow_turb/pTE_v_2d_to_om_z_2d_dsmpl_3x_max_values.h5";

D = 3.18e-3;
threshold = 0.9;

addpath(genpath(path_to_add));
te_mat = h5read(te_mat_file, '/ds')';
[ccw, ~] = compute_thresholded_weighted_closeness_centrality(te_mat, threshold);

%% saving as mat file
% Output file name

output_file = ['/scratch/asevivek/vivek_cases/000_datasets/000/' ...
    '_toolbox_outputs/network_analysis/compute_ccw/' ...
    'single_cylinder_Re7k_with_PGS_with_inflow_turb_pTE_based/' ...
    'ccw_pTE_om_z_2d_to_v_2d_dsmpl_3x_max_values.mat'];

% output_file = ['/scratch/asevivek/vivek_cases/000_datasets/000/' ...
%     '_toolbox_outputs/network_analysis/compute_ccw/' ...
%     'single_cylinder_Re7k_with_PGS_with_inflow_turb_pTE_based/' ...
%     'ccw_pTE_v_2d_to_om_z_2d_dsmpl_3x_max_values.mat'];

% Save ccw variable
save(output_file, 'ccw');

fprintf('ccw data saved to %s\n', output_file);

%% saving as h5 ffile
% Output HDF5 file

output_h5 = ['/scratch/asevivek/vivek_cases/000_datasets/000/' ...
    '_toolbox_outputs/network_analysis/compute_ccw/' ...
    'single_cylinder_Re7k_with_PGS_with_inflow_turb_pTE_based/' ...
    'ccw_pTE_om_z_2d_to_v_2d_dsmpl_3x_max_values.h5'];

% output_h5 = ['/scratch/asevivek/vivek_cases/000_datasets/000/' ...
%     '_toolbox_outputs/network_analysis/compute_ccw/' ...
%     'single_cylinder_Re7k_with_PGS_with_inflow_turb_pTE_based/' ...
%     'ccw_pTE_v_2d_to_om_z_2d_dsmpl_3x_max_values.h5'];

% Delete file if it already exists
if isfile(output_h5)
    delete(output_h5);
end

% Create dataset and write data
h5create(output_h5, '/ccw', size(ccw));
h5write(output_h5, '/ccw', ccw);

fprintf('ccw data saved to %s\n', output_h5);

%% plotting
coords_path = ['/scratch/asevivek/vivek_cases/000_datasets/' ...
    '001_single_cylinder_case_single_plane_spanwise_averaged_velocity_and_vorticitcy_fields/' ...
    'coords_2D_dsmpl_X3x_Y3x.h5'];
X = h5read(coords_path, '/X')';
Y = h5read(coords_path, '/Y')';
[nx, ny] = size(X);
ccw_2d = reshape(ccw, [ny,nx])';

plot_closeness_centrality_contour_field(ccw_2d, X, Y);