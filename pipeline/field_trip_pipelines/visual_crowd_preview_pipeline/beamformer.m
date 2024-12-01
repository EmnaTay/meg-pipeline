%% This script uses beamformer technique for source localisation


Atlas = ft_read_atlas('C:\Users\tasni\Desktop\Masterarbeit\atlas\aal\ROI_MNI_V4.nii');

% Load the MNI template MRI
mri = ft_read_mri('C:\Users\tasni\Desktop\Masterarbeit\anatomy\Subject01.mri');
mri = ft_convert_units(mri, 'mm');
template = ft_read_headmodel('standard_bem.mat');
template = ft_convert_units(template, 'mm');

cfg = [];
cfg.method = 'interactive';
cfg.coordsys = 'ctf';       % Ensure consistency with your MEG data's coordinate system
mri_init = ft_volumerealign(cfg, mri);

% Coregistration: MRI and headshape

cfg                     = [];
cfg.method              = 'headshape';
cfg.headshape.headshape = headshape;
cfg.headshape.interactive = 'no';
cfg.headshape.icp = 'yes';
mri_aligned           = ft_volumerealign(cfg, mri_init);

cfg = [];
cfg.grad              = grad;   %structure, see FT_READ_SENS
cfg.headshape         = headshape;   %structure, see FT_READ_HEADSHAPE
cfg.mri               = mri_aligned;
cfg.mesh              = headshape;
cfg.axes              = 'yes';

ft_geometryplot(cfg)

%% CREATING HEADMODEL (METHOD 2)

figure;
ft_plot_mesh(template.bnd(1));
ft_plot_mesh(headshape);

defaced_template      = template.bnd(1);
defaced_template.unit = template.unit;

cfg              = [];
cfg.translate    = [0 220 0];
cfg.scale        = [250 250 250];
cfg.rotate       = [0 0 0];
defaced_template =  ft_defacemesh(cfg, defaced_template);

cfg              = [];
cfg.translate    = [0 0 -100];
cfg.scale        = [200 200 200];
cfg.rotate       = [0 0 0];
defaced_polhemus =  ft_defacemesh(cfg, headshape);

% Question: the points of the headshape and template are being removed when
% inside the yellow box. 

figure;
ft_plot_mesh(defaced_template);
ft_plot_mesh(defaced_polhemus);



addpath(genpath('C:\Users\tasni\AppData\Roaming\MathWorks\MATLAB Add-Ons\Collections\CoherentPointDrift-master'))

% Prepare the configuration for the affine transformation
cfg                  = [];
cfg.headshape        = defaced_polhemus;
cfg.template         = defaced_template;
cfg.method           = 'fittemplate';
template_fit_surface = ft_prepare_mesh(cfg, template.bnd);

% NOTE: Cut on the Z-plane (from the coregistration) after the warping

%% COMPUTING HEADMODEL

addpath(genpath('C:\Users\tasni\AppData\Roaming\MathWorks\MATLAB Add-Ons\Collections\OpenMEEG-2.5.12-Windows\bin'))

% template_fit_sphere  = ft_convert_units(template_fit_sphere,'m');
template_fit_surface = ft_convert_units(template_fit_surface,'m');

% Visualize the individual surfaces of the head model
figure;
% ft_plot_mesh(template_fit_surface(1), 'facecolor', 'r');  % Scalp
ft_plot_mesh(template_fit_surface(3));  % Brain
hold on;
ft_plot_mesh(template_fit_surface(2), 'facecolor', 'g');  % Skull


% cfg = [];
% cfg.conductivity = [0.33 0.0042 0.33];  % Conductivities for scalp, skull, brain
% cfg.method = 'bemcp';
% cfg.isolatedsource = false;  % Set this to false for non-isolated source models
% cfg.tissue = {'scalp', 'skull', 'brain'};  % Specify the tissue labels if needed
% headmodel_surface = ft_prepare_headmodel(cfg, template_fit_surface);

% figure;
% ft_plot_mesh(headmodel_surface.bnd(1))
% ft_plot_mesh(headshape)

% figure;
% ft_plot_headmodel(headmodel_surface, 'facecolor', 'cortex', 'edgecolor', 'none', 'facealpha', 0.4);
% title('Head Model Computed Using BEMCP');

% SINGLESHELL
cfg                           = [];
cfg.method                    = 'singleshell';
headmodel_singleshell_surface = ft_prepare_headmodel(cfg, template_fit_surface(3));

figure;
ft_plot_headmodel(headmodel_singleshell_surface, 'facecolor', 'cortex', 'edgecolor', 'none', 'facealpha', 0.4);
title('Single-Shell Head Model Based on Brain Surface');




%% SOURCEMODEL

cfg = [];
cfg.headmodel = headmodel_singleshell_surface;
cfg.grad = grad; % this being needed here is a silly historical artifact
cfg.resolution = 7; % in SI units
cfg.unit = 'mm'; % ensure that the sourcemodel is expressed in SI units
sourcemodel = ft_prepare_sourcemodel(cfg);

figure
ft_plot_headmodel(headmodel_singleshell_surface, 'unit', 'mm');
ft_plot_sens(grad, 'unit', 'mm', 'coilsize', 10, 'chantype', 'meggrad');
ft_plot_mesh(sourcemodel.pos, 'unit', 'mm');
alpha 0.5


%% LEADFIELD

cfg = [];
cfg.channel = 'AG*';
cfg.headmodel = headmodel_singleshell_surface;
cfg.sourcemodel = sourcemodel;
cfg.normalize = 'yes'; % normalization avoids power bias towards centre of head
cfg.reducerank = 2;
leadfield = ft_prepare_leadfield(cfg, avgCWDG1);

% NOTE: try using non-averaged data (then average)

cfg = [];
cfg.channel = leadfield.cfg.channel;  % Only keep the channels present in the leadfield
CWDG1_aligned = ft_selectdata(cfg, avgCWDG1);

% NOTE: remove channel 91 in MEG_analysis_ERP 

%% SOURCEANALYSIS

cfg = [];
cfg.method = 'lcmv';  % Beamforming method
cfg.sourcemodel = leadfield;  % Use the sourcemodel with leadfield
cfg.headmodel = headmodel_singleshell_surface;  % Use the head model
cfg.lcmv.keepfilter = 'yes';  % Keep the spatial filter
cfg.lcmv.lambda = '5%';  % Regularization parameter % high means priority to prior; low means priority for measurement
cfg.lcmv.kappa = 69;
cfg.lcmv.projectmom = 'yes'; 
cfg.lcmv.fixedori = 'yes';  % Use fixed orientation
cfg.lcmv.kurtosis = 'yes';
source = ft_sourceanalysis(cfg, dataCrowding1);  % 'meg_data' is your preprocessed MEG data
% NOTE: change scale of heatmap


% source is in m, mri_resliced is in mm, hence source_interp will also be in mm
cfg = [];
cfg.parameter = 'avg.pow';
source_interp = ft_sourceinterpolate(cfg, source, mri_aligned);


%% VISUALISE USING MRI TEMPLATE

cfg = [];
cfg.method = 'ortho';  % Orthogonal slices visualization
cfg.funparameter = 'pow';  % Parameter to plot
ft_sourceplot(cfg, source_interp);  % Visualize the source activity

cfg = [];
cfg.method = 'slice';
cfg.funparameter = 'pow';  % Parameter to plot
ft_sourceplot(cfg, source_interp);  % Plot on the atlas

%% VISUALISE USING ATLAS

% Warp/align the atlas (like the mri)