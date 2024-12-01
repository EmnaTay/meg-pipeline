%% This script uses MNE technique for source localisation


Atlas = ft_read_atlas('C:\Users\tasni\Desktop\Masterarbeit\atlas\aal\ROI_MNI_V4.nii');

% Load the MNI template MRI
mri = ft_read_mri('C:\Users\tasni\Desktop\Masterarbeit\anatomy\Subject01.mri');


cfg = [];
cfg.method = 'headshape';
cfg.headshape = headshape;  % This is the aligned headshape struct
cfg.coordsys = 'ctf';       % Ensure consistency with your MEG data's coordinate system
% Align the MRI to the headshape
mri_aligned = ft_volumerealign(cfg, mri);


%%
% Is this the warping??? 

ft_path = fileparts(which('ft_defaults'));  % Get FieldTrip path
template_file = fullfile(ft_path, 'template', 'anatomy', 'single_subj_T1.nii');  % Path to template file

cfg = [];
cfg.template = template_file;  % Use the loaded MRI structure as the template
cfg.nonlinear = 'yes';
cfg.spmversion = 'spm12';
mri_warped = ft_volumenormalise(cfg, mri_aligned);  % Normalize your aligned MRI to this template

ft_sourceplot([], mri_warped);  % Check the warped MRI


%% segmentation MRI
cfg           = [];
cfg.output    = {'brain', 'skull', 'scalp'};
segmentedmri  = ft_volumesegment(cfg, mri_aligned);

cfg = [];
cfg.method='singleshell';
mriskullmodel = ft_prepare_headmodel(cfg, segmentedmri);



cfg = [];
cfg.tissue      = {'brain', 'skull', 'scalp'};
cfg.numvertices = [3000 2000 1000];
mesh = ft_prepare_mesh(cfg, segmentedmri);

cfg = [];
%   cfg.elec              = structure, see FT_READ_SENS
   cfg.grad              = grad;%structure, see FT_READ_SENS
%   cfg.opto              = structure, see FT_READ_SENS
  cfg.headshape         = mesh(3); %structure, see FT_READ_HEADSHAPE
  cfg.headmodel         = mriskullmodel; % structure, see FT_PREPARE_HEADMODEL and FT_READ_HEADMODEL
%   cfg.sourcemodel       = structure, see FT_PREPARE_SOURCEMODEL
%   cfg.dipole            = structure, see FT_DIPOLEFITTING
  cfg.mri               = mri_aligned;
  cfg.mesh              = headshape;
  cfg.axes              = 'yes';

ft_geometryplot(cfg)

ft_plot_mesh(mesh);  % Plot the MRI surface mesh
hold on;
plot3(headshape.pos(:,1), headshape.pos(:,2), headshape.pos(:,3), 'r.');  % Overlay laser scan points




%% Sourcemodel

% brain_mask = ft_volumesegment([], mri_aligned);  % Create a brain mask
brain_mask = segmentedmri.brain;
cfg = [];
cfg.grid.resolution = 10;  % Grid resolution in mm
cfg.grid.unit = 'mm';
cfg.mri = mri_aligned;  % Your aligned and resliced MRI data
cfg.headmodel = mriskullmodel;  % The head model representing the brain/skull
cfg.inwardshift = 5;  % Optional: Shift the grid inward
cfg.grid.tight = 'yes';  % Ensure the grid is tightly constrained to the brain
cfg.grid.inside = brain_mask(:);  % Restrict grid points to brain mask
sourcemodel = ft_prepare_sourcemodel(cfg);



inside_idx = find(sourcemodel.inside);
plot3(sourcemodel.pos(inside_idx, 1), sourcemodel.pos(inside_idx, 2), sourcemodel.pos(inside_idx, 3), 'o');
ft_plot_vol(mriskullmodel, 'facecolor', 'cortex', 'edgecolor', 'none');

%% Leadfield

cfg         = [];
cfg.grad    = grad;   % sensor information
cfg.channel = dataCrowding1_matched.label;  % the used channels
cfg.grid    = sourcemodel;   % source points
cfg.headmodel = mriskullmodel;   % volume conduction model
cfg.singleshell.batchsize = 5000; % speeds up the computation
leadfield   = ft_prepare_leadfield(cfg);


cfg               = [];
cfg.method        = 'mne';  % Source analysis method (minimum norm estimate)
cfg.grid          = leadfield;  % Leadfield from ft_prepare_leadfield
cfg.headmodel     = mriskullmodel;  % Head model (e.g., single-shell or BEM)
cfg.mne.prewhiten = 'yes';  % Prewhitening to improve estimates
cfg.mne.lambda    = 3;  % Regularization parameter (adjust if needed)
cfg.mne.scalesourcecov = 'yes';  % Scale the source covariance
source1           = ft_sourceanalysis(cfg,dataCrowding1_matched);


% m=source1.avg.pow(:,400); % plotting the result at the 450th time-point that is
%                          % 500 ms after the zero time-point
% ft_plot_mesh(source1, 'vertexcolor', m);
% view([180 0]); h = light; set(h, 'position', [0 1 0.2]); lighting gouraud; material dull

% Assuming you want to visualize power at the 400th time point
cfg = [];
cfg.method = 'surface';         % Surface plot
cfg.funparameter = 'avg.pow';    % Specify that we want to plot the power values
cfg.funcolormap = 'hot';         % Use the 'hot' colormap for visualization
cfg.latency = 0.4;               % Time point 400 corresponds to ~500 ms (depending on your data's time scale)
cfg.colorbar = 'yes';            % Show a color bar for reference

ft_sourceplot(cfg, source1);     % Plot the source model with power values

% Assuming your data has a time field with time points
% Check the time array in your data
disp(dataCrowding1_matched.time{1});  % Display time points for the first trial
