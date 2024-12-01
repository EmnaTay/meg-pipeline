% This script handles the co-registration of the coils and the
% headscan/stylus points 


clear all;
clc
% Define the base directory for your local data
baseDir = 'C:\Users\tasni\Desktop\Masterarbeit\Paradigm\previw and crowding\EXP DATA\'; % Update this to your actual local data directory

% Define paths for your files
confile = fullfile(baseDir, 'sub-001-vcp\MEG Data\sub-001-vcp.con');
laser_surf = fullfile(baseDir, 'sub-001-vcp\HeadScan Data\sub-001-scan-vcp.txt');
laser_points = fullfile(baseDir, 'sub-001-vcp\HeadScan Data\sub-001-scan-stylus-vcp.txt');
mrkfile1 = fullfile(baseDir, 'sub-001-vcp\Marker\sub-001-1-vcp.mrk');
mrkfile2 = fullfile(baseDir, 'sub-001-vcp\Marker\sub-001-1-vcp.mrk');

% Display the paths to ensure they are correct
disp(['Confile Path: ', confile]);
disp(['Laser Surface Path: ', laser_surf]);
disp(['Laser Points Path: ', laser_points]);


lasershape   = read_head_shape_laser(laser_surf,laser_points);
lasershape   = ft_convert_units(lasershape, 'mm');

laser2ctf = ft_headcoordinates(lasershape.fid.pos(1,:),lasershape.fid.pos(4,:),lasershape.fid.pos(5,:),'ctf');

%Apply the transformation to the laser head scan and fiducials
lasershape = ft_transform_geometry(laser2ctf, lasershape);

%Plot to inspect the geometrical object and ensure that this obeys the CTF
%references
lasershape = ft_determine_coordsys(lasershape, 'interactive', 'no');
lasershape.coordsys = 'ctf';
ft_plot_headshape(lasershape)

% Deface the laser mesh under a certain plan (change the 140) Define the configuration for ft_defacemesh
planecut = 75;
cfg = [];
cfg.method    = 'plane';       % Use a plane for exclusion
cfg.translate = [0 planecut 0]; % A point on the plane (adjust z_value as needed)
cfg.rotate    = [0 0 0];       % Rotation vector, modify if the plane is not axis-aligned
cfg.selection = 'outside';     % Remove points below the plane

% Apply ft_defacemesh to remove points below the plane
mesh = ft_defacemesh(cfg, lasershape);

% Plot the resulting mesh to check the results
ft_plot_mesh(mesh);
lasershape = mesh;

mrk1 = ft_read_headshape(mrkfile1);
mrk1 = ft_convert_units(mrk1, lasershape.unit);
mrk2 = ft_read_headshape(mrkfile2);
mrk2 = ft_convert_units(mrk2, lasershape.unit);

%% 
% Define the average marker positions, mrk1 correspond to HPI coils at the
% beginning and end of the experiment
mrka = mrk1;
mrka.fid.pos = (mrk1.fid.pos+mrk2.fid.pos)/2;

% p1 holds all the marker points 
p_coils = mrka.fid.pos(1:5,:);
p_headscan = lasershape.fid.pos;

% extracting the coordinates for the coils 
x_p_coils = p_coils(:, 1); 
y_p_coils = p_coils(:, 2);
z_p_coils = p_coils(:, 3);

% extracting the coordinates for the headscan/stylus points 
x_headscan = p_headscan(:, 1);
y_headscan = p_headscan(:, 2);
z_headscan = p_headscan(:, 3);

% Plotting a 3D scatter plot of the head scan points and the coils before
% transforming 
scatter3(x_headscan, y_headscan, z_headscan, 'filled'); % plot of the head scan points in 3D
hold on
scatter3(x_p_coils,y_p_coils,z_p_coils, 'filled') % plot of the coils 

% Adding labels to the coil points
for i = 1:length(mrka.fid.label)
    text(x_p_coils(i), y_p_coils(i), z_p_coils(i), mrka.fid.label{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end

% Adding labels to the headshape points
for i = 1:length(lasershape.fid.label)
    text(x_headscan(i), y_headscan(i), z_headscan(i), lasershape.fid.label{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
end

%%


% "black coil" is Number 1 (nas) in the .mrk which correspond to 6 (CF) in the stylus
% points
% "red coil" is number 2 (lpa) in the .mrk which correspond to 4 (LPA) in the stylus
% "yellow coil" is number 3 (rpa) in the .mrk which correspond to 5 (RPA) in the stylus
% "white coil" is number 4 (marker 4) in the .mrk which correspond to 7 (LF) in the stylus
% "blue coil" is number 5 (marker 5) in the .mrk which correspond to 8 (RF) in the stylus
t1 = ft_headcoordinates(p_coils(1,:), p_coils(2,:), p_coils(3,:), 'ctf');%J
t2 = ft_headcoordinates(p_headscan(6,:), p_headscan(4,:), p_headscan(5,:), 'ctf');%J

% t2\t1 is interpreted as the transformation t that, if you apply t to a
% point, then you apply t1 on the resulting point, becomes as if you
% applied t2 on that point, this means the composition t1(t(point)) = t2

transform_mrk2laser = t2\t1; % from sensor to headshape / from sensor to laser
% p1t = ft_warp_apply(transform_mrk2laser, p1)

grad = ft_read_sens(confile,'senstype','meg');
grad= ft_transform_geometry(transform_mrk2laser, grad);

transform_mrk2laser = transform_mrk2laser(1:3,:);
TR = transform_mrk2laser(:,1:3);
TT = transform_mrk2laser(:,4);

transformed_coils = TR*p_coils' + TT;

%%
% extracting the coordinates of the transformed coils 
transformed_coils_x = transformed_coils(1,:);
transformed_coils_y = transformed_coils(2,:);
transformed_coils_z = transformed_coils(3,:);

% plot the transformed coils and the headscan/stylus points for
% confirmation
figure
scatter3(transformed_coils(1,:), transformed_coils(2,:),transformed_coils(3,:), 'filled') % plot of the transformed coils
hold on
scatter3(x_headscan, y_headscan, z_headscan, 'filled'); % Plot of the laser scan points/stylus points
% scatter3(x_p_coils,y_p_coils,z_p_coils, 'filled') % plot the p_coils
% before transformation for comparison

% Add labels to the headshape points (assuming lasershape.fid.label exists)
for i = 1:length(lasershape.fid.label)
    text(x_headscan(i), y_headscan(i), z_headscan(i), lasershape.fid.label{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
end
% Add labels to the headshape points (assuming lasershape.fid.label exists)
for i = 1:length(mrka.fid.label)
    text(transformed_coils_x(i), transformed_coils_y(i), transformed_coils_z(i), mrka.fid.label{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
end