%% We coregister a template headmodel with our polhemus

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



%% 2. Coregister a template headmodel with our polhemus 
% (normally we use an individual MRI, but we do not have that - see https://www.fieldtriptoolbox.org/example/fittemplate/)

%% Template headmodel 

template = ft_read_headmodel('standard_bem.mat');
template = ft_convert_units(template, 'm');

%% Coregister template headmodel with polhemus headshape

cfg = [];
cfg.template.headshape      = lasershape_laser2ctf;
cfg.individual.headmodel    = template;
cfg.unit                    = 'm';
cfg                         = ft_interactiverealign(cfg); % rotation 0 25 -90, translate 0.03 0 0.045

template_coreg              = ft_transform_geometry(cfg.m, template);

% Check
figure;
ft_plot_sens(grad_mrk2ctf)
hold on
ft_plot_headshape(lasershape_laser2ctf)
hold on
ft_plot_headmodel(template_coreg)
title('before refinement')

%%

% note that the template's precomputed system matrix needs to be deleted
% because this gives problems with spatial transformations
template_coreg = rmfield(template_coreg, 'mat');

%% Improve/Refine coregistration 

% remove the part below the nasion
cfg = [];
cfg.rotate = [0 30 0];
cfg.translate = [0 0 55];
cfg.method    = 'plane';     
cfg.selection = 'outside';
cfg.unit ='m';
headshape_denosed = ft_defacemesh(cfg, lasershape_laser2ctf);

cfg             = [];
cfg.method      = 'singlesphere';
sphere_template = ft_prepare_headmodel(cfg, template_coreg.bnd(1));

cfg              = [];
cfg.method      = 'singlesphere';
sphere_polhemus = ft_prepare_headmodel(cfg, headshape_denosed);

scale = sphere_polhemus.r/sphere_template.r;

T1 = [1 0 0 -sphere_template.o(1);
      0 1 0 -sphere_template.o(2);
      0 0 1 -sphere_template.o(3);
      0 0 0 1                ];

S  = [scale 0 0 0;
      0 scale 0 0;
      0 0 scale 0;
      0 0 0 1 ];

T2 = [1 0 0 sphere_polhemus.o(1);
      0 1 0 sphere_polhemus.o(2);
      0 0 1 sphere_polhemus.o(3);
      0 0 0 1                 ];


template2polhemus = T2*S*T1;

template_fit_sphere = ft_transform_geometry(template2polhemus, template_coreg, 'scale'); 

template_fit_sphere.type = template.type;

% Check
figure;
ft_plot_sens(grad_mrk2ctf)
hold on
ft_plot_headshape(lasershape_laser2ctf)
hold on
ft_plot_headmodel(template_fit_sphere)
title('after refinement') % The frontal areas are better coregistered after the refinement. However, the occipito-parietal areas are not coregistered well.

%% Singleshell headmodel on the basis of the brain compartment

cfg                          = [];
cfg.method                   = 'singleshell';
headmodel_singleshell_sphere = ft_prepare_headmodel(cfg, template_fit_sphere.bnd(3));

%% 3. Generate sourcemodel based on headmodel

cfg           = [];
cfg.method    = 'basedonvol';
cfg.headmodel = headmodel_singleshell_sphere; 
cfg.unit      = 'm';
sourcemodel_hdm   = ft_prepare_sourcemodel(cfg); % generating 1500 dipoles as many as headmodel_singleshell_sphere.bnd.pos has

% make a figure of the single subject headmodel, and grid positions
figure; hold on;
ft_plot_headmodel(headmodel_singleshell_sphere, 'edgecolor', 'none', 'facealpha', 0.4);
ft_plot_mesh(sourcemodel_hdm.pos(sourcemodel_hdm.inside,:)); % there is only the cortical surface!

% Next I need to use this method for group analysis: https://www.fieldtriptoolbox.org/tutorial/sourcemodel/#interpolation-followed-by-spatial-normalization

%% 4. Generate leadfield

%% Way1: we need sourcemodel (see https://www.fieldtriptoolbox.org/tutorial/beamformer_lcmv/)

cfg                  = [];
cfg.grad             = grad_mrk2ctf;  
cfg.headmodel        = headmodel_singleshell_sphere;   
cfg.sourcemodel      = sourcemodel_hdm;
cfg.channel          = {'MEG'};
cfg.singleshell.batchsize = 2000;
cfg.normalize        = 'yes'; % control against the power bias towards the center of the head. However, if you are going to contrast two conditions (eg, avgCWDG1 vs avgCWDG2) do NOT do this normalisation
lf                   = ft_prepare_leadfield(cfg);

%% Way2: we do not need sourcemodel (see https://www.fieldtriptoolbox.org/tutorial/beamformer/#source-model-and-lead-fields)

cfg                  = [];
cfg.grad             = grad_mrk2ctf;
cfg.headmodel        = headmodel_singleshell_sphere;
cfg.reducerank       = 2; % default = 2 for MEG
cfg.channel          = {'MEG'};
cfg.resolution       = 0.01; % use a 3-D grid with a 0.01 m resolution
cfg.sourcemodel.unit = 'm';
cfg.normalize        = 'yes'; % control against the power bias towards the center of the head. However, if you are going to contrast two conditions (eg, avgCWDG1 vs avgCWDG2) do NOT do this normalisation
sourcemodel_lf          = ft_prepare_leadfield(cfg);

figure;
scatter3(sourcemodel_lf.pos(:,1), sourcemodel_lf.pos(:,2), sourcemodel_lf.pos(:,3));

% it is a box with the source points. Later we need to interpolate that box
% to the individual MRI to be able to plot and see where the activity is


%% 5. Beamformer

% create spatial filter using the lcmv beamformer
cfg                  = [];
cfg.method           = 'lcmv';
cfg.sourcemodel      = sourcemodel_lf; 
cfg.headmodel        = headmodel_singleshell_sphere; 
cfg.lcmv.keepfilter  = 'yes';
cfg.lcmv.fixedori    = 'yes'; % project on axis of most variance using SVD
source1               = ft_sourceanalysis(cfg, avgCWDG1); 

%% 6. Plot beamformer only on the cortical surface. If we want to plot it in the whole volume we need to make subject-specific sourcemodel using the **subject-specific mri**

cfg            = [];
cfg.downsample = 2;
cfg.parameter  = 'pow';
source1_intrp  = ft_sourceinterpolate(cfg, source1, sourcemodel_hdm);

cfg              = [];
cfg.method       = 'vertex';
cfg.funparameter = 'pow';
ft_sourceplot(cfg, source1_intrp, sourcemodel_hdm); % the bigger the circle, the higher the activity