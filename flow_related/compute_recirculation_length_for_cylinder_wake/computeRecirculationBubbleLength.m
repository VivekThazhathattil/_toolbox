function [Lr_over_D, x_r, results] = ...
    computeRecirculationBubbleLength( ...
    coords_h5_file, ...
    bluff_body_diameter, ...
    Uinf, ...
    u_input, ...
    varargin)
% ========================================================================
% COMPUTERECIRCULATIONBUBBLELENGTH
%
% Compute recirculation bubble length from streamwise velocity field
% of a bluff body wake.
%
% INPUTS
% ========================================================================
%
% coords_h5_file        : path to coords_2D.h5
%
% bluff_body_diameter   : bluff body diameter D
%
% Uinf                  : freestream/reference velocity
%
% u_input               : either
%                         (1) path to u_2d.h5
%                         OR
%                         (2) matrix of size
%                             [num_spatial_points x nt]
%
%
% OPTIONAL NAME-VALUE PAIRS
% ========================================================================
%
% 'CenterlineY'         : wake centerline location
%                          default = 0
%
% 'BodyCenterX'         : bluff body center x-location
%                          default = 0
%
% 'VelocityThreshold'   : threshold for sign change
%                          default = 0.01
%
% 'FigureVisible'       : 'on' or 'off'
%                          default = 'on'
%
%
% OUTPUTS
% ========================================================================
%
% Lr_over_D             : recirculation bubble length / D
%
% x_r                   : reattachment location
%
% results               : struct
%
% ========================================================================

%% =======================================================================
% Parse inputs
%% =======================================================================

p = inputParser;

addParameter(p,'CenterlineY',0);
addParameter(p,'BodyCenterX',0);
addParameter(p,'VelocityThreshold',0.01);
addParameter(p,'FigureVisible','on');

parse(p,varargin{:});

y_center      = p.Results.CenterlineY;
x_body_center = p.Results.BodyCenterX;
u_threshold   = p.Results.VelocityThreshold;
fig_visible   = p.Results.FigureVisible;

D = bluff_body_diameter;

%% =======================================================================
% Load coordinates
%% =======================================================================

X = h5read(coords_h5_file,'/X')';
Y = h5read(coords_h5_file,'/Y')';

[num_x,num_y] = size(X);
num_points = num_x * num_y;

fprintf('\nLoaded coordinates\n');
fprintf('num_x = %d\n',num_x);
fprintf('num_y = %d\n',num_y);

%% =======================================================================
% Load velocity data
%% =======================================================================

if ischar(u_input) || isstring(u_input)

    fprintf('\nLoading velocity from h5...\n');
    U_flat = h5read(u_input,'/ds')';

else

    fprintf('\nUsing supplied velocity matrix...\n');
    U_flat = u_input;

end

[num_loaded,nt] = size(U_flat);

if num_loaded ~= num_points
    error(['Mismatch in number of spatial points.\n' ...
           'Expected %d but found %d'], ...
           num_points, num_loaded);
end

fprintf('Number of snapshots = %d\n',nt);

%% =======================================================================
% Normalize velocity
%% =======================================================================

fprintf('\nNormalizing velocity using Uinf = %.6f\n',Uinf);

U_flat = U_flat ./ Uinf;

%% =======================================================================
% Compute mean velocity field
%% =======================================================================

U_mean_flat = mean(U_flat,2);

%% =======================================================================
% Reshape to (num_x x num_y)
%% =======================================================================
%
% Original python shape:
%
%   (num_x, num_y, nt)
%
% flattened to:
%
%   (num_x*num_y, nt)
%
% reconstruct WITHOUT transpose
%
%% =======================================================================

U_mean = reshape(U_mean_flat,[num_x,num_y]);

%% =======================================================================
% Find centerline
%% =======================================================================

y_vector = Y(1,:);

[~,iy_center] = min(abs(y_vector - y_center));

actual_y = y_vector(iy_center);

fprintf('\nUsing centerline y = %.6f\n',actual_y);

%% =======================================================================
% Extract centerline velocity
%% =======================================================================

x_line = X(:,iy_center);
u_line = U_mean(:,iy_center);

%% =======================================================================
% Only downstream of cylinder rear
%% =======================================================================

x_rear = x_body_center + D/2;

idx_downstream = x_line >= x_rear;

x_down = x_line(idx_downstream);
u_down = u_line(idx_downstream);

%% =======================================================================
% First negative-to-positive crossing
%% =======================================================================

idx_cross = find( ...
    u_down(1:end-1) < -u_threshold & ...
    u_down(2:end) >= u_threshold, ...
    1,'first');

if isempty(idx_cross)

    warning('No recirculation bubble detected.');

    x_r = NaN;
    Lr_over_D = NaN;

else

    x_r = interp1( ...
        u_down(idx_cross:idx_cross+1), ...
        x_down(idx_cross:idx_cross+1), ...
        0, ...
        'linear');

    Lr = x_r - x_rear;
    Lr_over_D = Lr / D;

end

fprintf('\nRecirculation bubble results\n');
fprintf('x_r   = %.6f\n',x_r);
fprintf('Lr/D  = %.6f\n',Lr_over_D);

%% =======================================================================
% Plotting
%% =======================================================================

figure( ...
    'Color','w', ...
    'Visible',fig_visible);

tiledlayout(1,2, ...
    'Padding','compact', ...
    'TileSpacing','compact');

fontsize = 18;
linewidth = 2;

%% =======================================================================
% Mean velocity contour
%% =======================================================================

nexttile;

contourf( ...
    X./D, ...
    Y./D, ...
    U_mean, ...
    100, ...
    'LineColor','none');

hold on;

% recirculation bubble contour (u/Uinf = 0)
contour( ...
    X./D, ...
    Y./D, ...
    U_mean, ...
    [0 0], ...
    'm', ...
    'LineWidth',2.5);

% zero crossing point
plot( ...
    x_r/D, ...
    actual_y/D, ...
    'mo', ...
    'MarkerFaceColor','m', ...
    'MarkerSize',10);

xlabel('$x/D$','Interpreter','latex');
ylabel('$y/D$','Interpreter','latex');

title( ...
    sprintf('$L_r/D = %.3f$',Lr_over_D), ...
    'Interpreter','latex');

cb = colorbar;
ylabel(cb,'$u/U_\infty$', ...
    'Interpreter','latex');

axis equal tight;
box on;

set(gca, ...
    'FontSize',fontsize, ...
    'LineWidth',1.5);

%% =======================================================================
% Centerline velocity
%% =======================================================================

nexttile;

plot( ...
    x_down./D, ...
    u_down, ...
    'k-', ...
    'LineWidth',linewidth);

hold on;

yline(0,'--','LineWidth',1.5);

xline( ...
    x_r/D, ...
    'm--', ...
    'LineWidth',2);

plot( ...
    x_r/D, ...
    0, ...
    'mo', ...
    'MarkerFaceColor','m', ...
    'MarkerSize',10);

xlabel('$x/D$','Interpreter','latex');
ylabel('$u/U_\infty$','Interpreter','latex');

title('Centerline Streamwise Velocity');

legend( ...
    {'$u/U_\infty$', ...
     '$u=0$', ...
     'Reattachment'}, ...
    'Interpreter','latex', ...
    'Location','eastoutside');

grid on;
box on;

set(gca, ...
    'FontSize',fontsize, ...
    'LineWidth',1.5);

%% =======================================================================
% Output structure
%% =======================================================================

results = struct();

results.X = X;
results.Y = Y;
results.U_mean = U_mean;

results.x_line = x_line;
results.u_line = u_line;

results.actual_y = actual_y;

results.x_rear = x_rear;
results.x_r = x_r;
results.Lr_over_D = Lr_over_D;
results.Uinf = Uinf;

end