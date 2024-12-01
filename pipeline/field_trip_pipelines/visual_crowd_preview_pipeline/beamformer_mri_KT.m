%% We coregister a template mri with our polhemus

%% configure paths

MEG_DATA_FOLDER = getenv('MEG_DATA');

% Set path to KIT .con file of sub-03
DATASET_PATH = [MEG_DATA_FOLDER,'visual_crowding_preview'];

% This needs fixing to save properly
SAVE_PATH = [MEG_DATA_FOLDER, 'visual_crowding_preview'];

%% MEGFILES, POLHEMUS_FILES, MRK_FILES

% Get a list of all MEG data files
MEGFILES = dir(fullfile(DATASET_PATH, 'sub-*-vcp','meg-kit', 'sub-*-vcp-analysis_NR.con'));

% Get a list of all the Polhemus files
POLHEMUS_FILES = dir(fullfile(DATASET_PATH, 'sub-*-vcp','digitizer', 'sub-*-scan*.txt'));

% Get a list of all the .mrk files
MRK_FILES = dir(fullfile(DATASET_PATH, 'sub-*-vcp','meg-kit', '*.mrk'));

for k = 1

    % Get the current MEG data file name   
    confile = fullfile(MEGFILES(k).folder, MEGFILES(k).name);

    laser_stylus = fullfile(POLHEMUS_FILES(k).folder, POLHEMUS_FILES(k).name);
    laser_surf = fullfile(POLHEMUS_FILES(k+1).folder, POLHEMUS_FILES(k+1).name);

    mrkfile1 = fullfile(MRK_FILES(k).folder, MRK_FILES(k).name);
    mrkfile2 = fullfile(MRK_FILES(k+1).folder, MRK_FILES(k+1).name);

end

% Display the paths to ensure they are correct
disp(['Confile Path: ', confile]);
disp(['Laser Surface Path: ', laser_surf]);
disp(['Laser Points Path: ', laser_stylus]);

%% 1. Load ERFs and coregistered lasershape/sensors

for k = 1

    % Define the subject ID based on k
    subject_id = sprintf('sub-%03d-vcp', k);
    
    % Define the folder path
    derivatives_folder = fullfile(SAVE_PATH, subject_id, 'derivatives');

    % ERFs (from MEG_analysis_ERP_KT.m)
    load(fullfile(derivatives_folder, 'avgCWDG1.mat'), 'avgCWDG1');
    load(fullfile(derivatives_folder, 'avgCWDG2.mat'), 'avgCWDG2');
    load(fullfile(derivatives_folder, 'avgCWDG3.mat'), 'avgCWDG3'); 
    
    % coregistered lasershape/sensors (from coregistration_KT.m)
    load(fullfile(derivatives_folder, 'grad_mrk2ctf.mat'), 'grad_mrk2ctf');
    load(fullfile(derivatives_folder, 'lasershape_laser2ctf.mat'), 'lasershape_laser2ctf');

end 

%% 2. Coregister a template mri with our polhemus (see https://www.fieldtriptoolbox.org/example/sphere_fitting/)

load standard_mri
mri = ft_convert_units(mri, 'm');

cfg           = [];
cfg.output    = {'brain','skull','scalp'};
segmentedmri  = ft_volumesegment(cfg, mri);

cfg             = [];
cfg.tissue      = {'scalp'};
cfg.numvertices = 3600;
bnd             = ft_prepare_mesh(cfg, segmentedmri);

cfg             = [];
cfg.tissue      = {'brain'};
cfg.numvertices = 3600;
bnd_brain       = ft_prepare_mesh(cfg, segmentedmri);

% remove the part below the nasion
cfg = [];
cfg.translate = [0 0 -30];
cfg.scale     = [0.300 0.300 0.300];
cfg.method    = 'plane';     
cfg.selection = 'outside';
bnd_deface = ft_defacemesh(cfg, bnd);

% remove the part below the nasion
cfg = [];
cfg.rotate = [0 30 0];
cfg.translate = [0 0 55];
cfg.method    = 'plane';     
cfg.selection = 'outside';
cfg.unit      ='m';
headshape_denosed = ft_defacemesh(cfg, lasershape_laser2ctf);

% check
figure
ft_plot_mesh(bnd_deface, 'edgecolor', 'none', 'facecolor', 'skin', 'facealpha',0.9)
ft_plot_headshape(headshape_denosed)
camlight 

%% Coregister manually

cfg = [];
cfg.template.headshape      = headshape_denosed;
cfg.individual.mesh         = bnd;
cfg.unit                    = 'm';
cfg                         = ft_interactiverealign(cfg); % rotate 0 30 -90 translate 0 0 0 

bnd_coreg                   = ft_transform_geometry(cfg.m, bnd_deface);
bnd_brain_coreg             = ft_transform_geometry(cfg.m, bnd_brain);
mri_coreg                   = ft_transform_geometry(cfg.m, mri);

% Check
figure;
ft_plot_sens(grad_mrk2ctf)
hold on
ft_plot_headshape(headshape_denosed)
hold on
ft_plot_mesh(bnd_coreg, 'edgecolor', 'none', 'facecolor', 'skin', 'facealpha',0.9)
ft_plot_mesh(bnd_brain_coreg , 'edgecolor', 'none', 'facecolor', 'brain', 'facealpha',  0.5)
title('before refinement')

%% Improve/Refine co-registration 

% fit a sphere to the MRI template
cfg=[];
cfg.method='singlesphere';
sphere_bnd = ft_prepare_headmodel(cfg, bnd_coreg);

% fit a sphere to the polhemus headshape
cfg=[];
cfg.method = 'singlesphere';
sphere_polhemus = ft_prepare_headmodel(cfg, headshape_denosed);

scale = sphere_polhemus.r/sphere_bnd.r;

T1 = [1 0 0 -sphere_bnd.o(1);
      0 1 0 -sphere_bnd.o(2);
      0 0 1 -sphere_bnd.o(3);
      0 0 0 1                ];

S  = [scale 0 0 0;
      0 scale 0 0;
      0 0 scale 0;
      0 0 0 1 ];

T2 = [1 0 0 sphere_polhemus.o(1);
      0 1 0 sphere_polhemus.o(2);
      0 0 1 sphere_polhemus.o(3);
      0 0 0 1                 ];


bnd2polhemus = T2*S*T1;

bnd_coreg_sphere = ft_transform_geometry(bnd2polhemus, bnd_coreg);
bnd_brain_coreg_sphere  = ft_transform_geometry(bnd2polhemus, bnd_brain_coreg);
mri_coreg_sphere        = ft_transform_geometry(bnd2polhemus, mri_coreg);


% Check
figure;
ft_plot_sens(grad_mrk2ctf)
hold on
ft_plot_headshape(lasershape_laser2ctf)
hold on
ft_plot_mesh(bnd_coreg_sphere, 'edgecolor', 'none', 'facecolor', 'skin', 'facealpha',0.9)
ft_plot_mesh(bnd_brain_coreg_sphere , 'edgecolor', 'none', 'facecolor', 'brain', 'facealpha',  0.5)
hold on
title('after refinement')

% check
cfg = [];
cfg.template.headshape      = lasershape_laser2ctf;
cfg.individual.mri         = mri_coreg_sphere;
cfg.unit                    = 'm';
cfg                         = ft_interactiverealign(cfg); % they are coregistered

% Next I can use this method for group analysis:
% https://www.fieldtriptoolbox.org/tutorial/sourcemodel/#procedure-1


%% 3. Make subject-specific sourcemodel using the subject-specific mri (default - see https://www.fieldtriptoolbox.org/tutorial/sourcemodel/#performing-group-analysis-on-3-dimensional-source-reconstructed-data)

%% Template grid 

load standard_sourcemodel3d10mm
template_grid = sourcemodel;
clear sourcemodel;

template_grid= ft_convert_units(template_grid, 'm');

% check
figure
ft_plot_mesh(template_grid.pos(template_grid.inside,:));

%% Warped grid

cfg           = [];
cfg.method    = 'basedonmni';
cfg.template  = template_grid;
cfg.nonlinear = 'yes';
cfg.mri       = mri_coreg_sphere;
sourcemodel   = ft_prepare_sourcemodel(cfg);

%% Headmodel

cfg                = [];
cfg.method         = 'singleshell';
headmodel          = ft_prepare_headmodel(cfg, bnd_brain_coreg_sphere);

%%

figure; hold on;
ft_plot_headmodel(headmodel, 'edgecolor', 'none', 'facecolor', 'brain','facealpha', 0.4);
hold on
ft_plot_mesh(sourcemodel.pos(sourcemodel.inside,:));

%% 4. Generate leadfield

%% We need sourcemodel (see https://www.fieldtriptoolbox.org/tutorial/beamformer_lcmv/)

cfg                  = [];
cfg.grad             = grad_mrk2ctf;  % gradiometer distances
cfg.headmodel        = headmodel;   % volume conduction headmodel
cfg.sourcemodel      = sourcemodel;
cfg.channel          = {'MEG'};
cfg.singleshell.batchsize = 2000;
cfg.normalize        = 'yes'; % control against the power bias towards the center of the head. However, if you are going to contrast two conditions (eg, avgCWDG1 vs avgCWDG2) do NOT do this normalisation
lf                   = ft_prepare_leadfield(cfg);




%% 5. Beamformer

% create spatial filter using the lcmv beamformer
cfg                  = [];
cfg.method           = 'lcmv';
cfg.sourcemodel      = lf; % leadfield
cfg.headmodel        = headmodel; % volume conduction model (headmodel)
cfg.lcmv.keepfilter  = 'yes';
cfg.lcmv.fixedori    = 'yes'; % project on axis of most variance using SVD
sourceCWDG1               = ft_sourceanalysis(cfg, avgCWDG1); 

%% 6. Plot activity

cfg              = [];
cfg.method       = 'ortho';
% cfg.interactive   = 'yes';
cfg.latency  =  [0.26 0.29];
cfg.funparameter = 'pow';
ft_sourceplot(cfg, source1, mri_coreg_sphere); 