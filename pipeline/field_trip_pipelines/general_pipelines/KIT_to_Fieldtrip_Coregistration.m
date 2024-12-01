% MRI-MEG KIT coregisteration

clear all
close all
clc

%% 

BOX_DIR = getenv('BOX_DIR');
disp(BOX_DIR)

% It is important that you use T1.mgz instead of orig.mgz as T1.mgz is normalized to [255,255,255] dimension
mrifile         = fullfile([BOX_DIR,'oddball\sub-03\anat\sub-003\sub-003\mri\T1.mgz']);
confile         = fullfile([BOX_DIR,'oddball\sub-03\meg-kit\sub-03-raw-kit.con']);    
laser_surf      = fullfile([BOX_DIR,'oddball\sub-03\meg-kit\sub-03-basic-surface.txt']);
%The cleaned stylus points removes the last three columns (dx, dx, dz) and
%keeps only x,y,z
laser_points    = [BOX_DIR, 'oddball\sub-03\meg-kit\sub-03-stylus-cleaned.txt'];
mrkfile1        = [BOX_DIR,'oddball\sub-03\meg-kit\240524-1.mrk'];
mrkfile2        = [BOX_DIR, 'oddball\sub-03\meg-kit\240524-2.mrk'];

%% Read Laser headshape (points and fudicials)

% lasershape is a structure containing the head points and fiducials 
% in the order specified at 
% https://meg-pipeline.readthedocs.io/en/latest/2-operationprotocol/operationprotocol.html
lasershape   = read_head_shape_laser(laser_surf,laser_points);


% This function estimates the current SI unit based on a typical head
% lenght (20cm) and converts it to any SI unit
lasershape   = ft_convert_units(lasershape, 'cm');


% From Fieldtrip we quote the right questions to ask for coordinate systems
% What is the definition of the origin of the coordinate system, i.e. where is [0,0,0]?
% In which directions are the x-, y- and z-axis pointing, i.e. is +x towards the right or towards anterior?
% In what units are coordinates expressed, i.e. does the number “1” mean 1 meter, 1 centimeter or 1 millimeter?
% Is the geometry scaled to some template or atlas, or does it still match the individual’s head/brain size?

% The NAS (Nasion) is the first point in the stylus file
% The LPA (Left Pre Aucular) is the 4th point in the stylus file
% The RPA (Right Pre Aucular) is the 5th point in the stylus file

%Quoting from fieldtrip ft_headcoordinates docstring
% The CTF, 4D, YOKOGAWA and EEGLAB coordinate systems are defined as follows:
%   the origin is exactly between lpa and rpa
%   the X-axis goes towards nas
%   the Y-axis goes approximately towards lpa, orthogonal to X and in the plane spanned by the fiducials
%   the Z-axis goes approximately towards the vertex, orthogonal to X and Y

% Return the transformation matrix from the fiducials coordinate space to
% CTF
% The transformation matrix is a 4x4 matrix the first 3x3 matrix is the
% rotation matrix
% The last column is the translation vector
laser2ctf = ft_headcoordinates(lasershape.fid.pos(1,:),lasershape.fid.pos(4,:),lasershape.fid.pos(5,:),'ctf');

%Apply the transformation to the laser head scan and fiducials
lasershape = ft_transform_geometry(laser2ctf, lasershape)

%Plot to inspect the geometrical object and ensure that this obeys the CTF
%references
ft_determine_coordsys(lasershape, 'interactive', 'no')

% Deface the laser mesh under a certain plan (change the 140) Define the configuration for ft_defacemesh
planecut = 140;
cfg = [];
cfg.method    = 'plane';       % Use a plane for exclusion
cfg.translate = [0 planecut 0]; % A point on the plane (adjust z_value as needed)
cfg.rotate    = [0 0 0];       % Rotation vector, modify if the plane is not axis-aligned
cfg.selection = 'outside';     % Remove points below the plane

% Apply ft_defacemesh to remove points below the plane
mesh = ft_defacemesh(cfg, lasershape);

% Plot the resulting mesh to check the results
ft_plot_mesh(mesh);
lasershape = mesh

%% read mri and mri-headshape
mri = ft_read_mri(mrifile); % read mri file
mri = ft_convert_units(mri, 'cm'); %make sure units cm

% Uncomment if you want to inspect MRI
% mri = ft_determine_coordsys(mri, 'interactive', 'no');



% Define the Nasion (N), LPA (L), RPA (R) and a Z-point that is in the positive z-axis (e.g. at top of brain) by first selecting the
% fiducial on the MRI then pressing the corresponding letter (N, L, R and Z) on your
% keyboard
% TODO: ensure the right and left side match the anatomical left and right
cfg             = [];
cfg.method      = 'interactive';
cfg.coordsys    = 'ctf'; %use CTF coordinates (pos x toward nose, +y to left)
mri_init = ft_volumerealign(cfg,mri)
ft_determine_coordsys(mri_init, 'interactive', 'no'); % sanity check, should be CTF

save data/mri_init mri_init

%% Align MEG Dewar to Laser scan Head model
% now we want to align the 3 markers in the *.con file with the 3 markers
% in the lasershape, where 1:5 markers match to the 4:9 lasershape
% fiducials
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
p_coils2 = mrka.fid.pos(1:3,:);
p_headscan = lasershape.fid.pos;

x = p_headscan(:, 1);
y = p_headscan(:, 2);
z = p_headscan(:, 3);

x_p_coils = p_coils(:, 1);
y_p_coils = p_coils(:, 2);
z_p_coils = p_coils(:, 3);


% Create a 3D scatter plot
scatter3(x, y, z, 'filled');
hold on
scatter3(x_p_coils,y_p_coils,z_p_coils, 'filled')


%% 
t1 = ft_headcoordinates(p_coils(1,:), p_coils(2,:), p_coils(3,:), 'ctf');%J
t2 = ft_headcoordinates(p_headscan(6,:), p_headscan(4,:), p_headscan(5,:), 'ctf');%J


%Mapping from .mrk HPI Coils to the Stylus head point

% Blue coil is Number X in the .mrk which correspond to Y in the stylus
% points
% Yellow coil
% White coil
% Black coil
% Red coil

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

transformed_coords = TR*p_coils' + TT;
%%
[TR2, TT2]= icp(p_coils', p_headscan');
%%
figure
scatter3(transformed_coords(1,:), transformed_coords(2,:),transformed_coords(3,:), 'filled')
hold on
scatter3(x, y, z, 'filled');
scatter3(x_p_coils,y_p_coils,z_p_coils, 'filled')


save data/grad grad

%% align MRI and Laser
cfg = []
cfg.method = 'headshape';
cfg.headshape = lasershape;
cfg.headshape.interactive = 'no'
cfg.headshape.icp = 'yes'


% x axis is r
% y axis is a
% z axis is s
% then n
mri_aligned = ft_volumerealign(cfg,mri_init)
% ft_determine_coordsys(mri_aligned,'interactive', 'no')

save data/mri_aligned mri_aligned

%% segmentation MRI
cfg           = [];
cfg.output    = {'brain', 'skull', 'scalp'};
segmentedmri  = ft_volumesegment(cfg, mri_aligned);

save data/segmentedmri segmentedmri

cfg = [];
cfg.method='singleshell';
mriskullmodel = ft_prepare_headmodel(cfg, segmentedmri);

cfg = [];
cfg.tissue      = {'brain', 'skull', 'scalp'};
cfg.numvertices = [3000 2000 1000];
mesh = ft_prepare_mesh(cfg, segmentedmri);
% ft_plot_mesh(mesh(3), 'facecolor', 'none'); % scalp

save data/mriskullmodel mriskullmodel


%% 
cfg = [];
%   cfg.elec              = structure, see FT_READ_SENS
   cfg.grad              = grad;%structure, see FT_READ_SENS
%   cfg.opto              = structure, see FT_READ_SENS
  cfg.headshape         = mesh(3)%structure, see FT_READ_HEADSHAPE
  cfg.headmodel         = mriskullmodel% structure, see FT_PREPARE_HEADMODEL and FT_READ_HEADMODEL
%   cfg.sourcemodel       = structure, see FT_PREPARE_SOURCEMODEL
%   cfg.dipole            = structure, see FT_DIPOLEFITTING
  cfg.mri               = mri_aligned;
  cfg.mesh              = lasershape;
  cfg.axes              = 'yes'

ft_geometryplot(cfg)