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

%% ERF group analysis

SUBJECTS = dir(fullfile(DATASET_PATH, 'sub-*-vcp'));

avgCWDG1  = cell(size(SUBJECTS));
avgCWDG2  = cell(size(SUBJECTS));
avgCWDG3  = cell(size(SUBJECTS));

for k = 1:numel(SUBJECTS)

    % Define the subject ID based on k
    subject_id = sprintf('sub-%03d-vcp', k);
    
    % Define the folder path
    derivatives_folder = fullfile(SAVE_PATH, subject_id, 'derivatives');

    fprintf('loading data for subject %s\n', k);

    % Beamformer for each subject
    tmp = load(fullfile(derivatives_folder, 'avgCWDG1.mat'), 'avgCWDG1'); avgCWDG1{k} = tmp.avgCWDG1;
    tmp = load(fullfile(derivatives_folder, 'avgCWDG2.mat'), 'avgCWDG2'); avgCWDG2{k} = tmp.avgCWDG2;
    tmp = load(fullfile(derivatives_folder, 'avgCWDG3.mat'), 'avgCWDG3'); avgCWDG3{k} = tmp.avgCWDG3;

    clear tmp
end 

cfg = [];
grandavgCWDG1 = ft_timelockgrandaverage(cfg, avgCWDG1{:});
grandavgCWDG2 = ft_timelockgrandaverage(cfg, avgCWDG2{:});
grandavgCWDG3 = ft_timelockgrandaverage(cfg, avgCWDG3{:});

% plot
cfg = [];
cfg.xlim =  [0.26 0.29];
cfg.colorbar = 'yes';
ft_topoplotER(cfg, grandavgCWDG1);

%% Group analysis on beamformer data

SUBJECTS = dir(fullfile(DATASET_PATH, 'sub-*-vcp'));

sourceCWDG1  = cell(size(SUBJECTS));
sourceCWDG2  = cell(size(SUBJECTS));
sourceCWDG3  = cell(size(SUBJECTS));

% load mri and template sourcemodel
load standard_mri
mri = ft_convert_units(mri, 'm');

load standard_sourcemodel3d10mm
template_grid = sourcemodel;
clear sourcemodel;

template_grid = ft_convert_units(template_grid, 'm');

for k = 1:numel(SUBJECTS)

    % Define the subject ID based on k
    subject_id = sprintf('sub-%03d-vcp', k);
    
    % Define the folder path
    derivatives_folder = fullfile(SAVE_PATH, subject_id, 'derivatives');

    fprintf('loading data for subject %s\n', k);

    % Beamformer for each subject
    tmp = load(fullfile(derivatives_folder, 'sourceCWDG1.mat'), 'sourceCWDG1'); 
    tmp.sourceCWDG1.pos = template_grid.pos; % replace the positions in the beamformer with the normalized positions of the template sourcemodel
    sourceCWDG1{k} = tmp.sourceCWDG1;

    tmp = load(fullfile(derivatives_folder, 'sourceCWDG2.mat'), 'sourceCWDG2'); 
    tmp.sourceCWDG2.pos = template_grid.pos; % replace the positions in the beamformer with the normalized positions of the template sourcemodel
    sourceCWDG2{k} = tmp.sourceCWDG2;
    
    tmp = load(fullfile(derivatives_folder, 'sourceCWDG3.mat'), 'sourceCWDG3'); 
    tmp.sourceCWDG3.pos = template_grid.pos; % replace the positions in the beamformer with the normalized positions of the template sourcemodel
    sourceCWDG3{k} = tmp.sourceCWDG3;

    clear tmp
end 

% average in source space
cfg = [];
grandsourceCWDG1 = ft_sourcegrandaverage(cfg, sourceCWDG1{:});
grandsourceCWDG2 = ft_sourcegrandaverage(cfg, sourceCWDG2{:});
grandsourceCWDG3 = ft_sourcegrandaverage(cfg, sourceCWDG3{:});

% plot
cfg              = [];
cfg.method       = 'ortho';
cfg.latency      =  [0.26 0.29];
cfg.funparameter = 'pow';
ft_sourceplot(cfg, grandsourceCWDG1, mri); 

%% Do statistics -  this depends on your research question, e.g., lets say we compare source activity of CWDG1 and CWDG2 using cluster based permutation which takes care of the multiple comparisons problem: https://www.fieldtriptoolbox.org/tutorial/cluster_permutation_timelock/

cfg = [];
cfg.method           = 'montecarlo'; % Cluster-based permutation testing
cfg.statistic        = 'depsamplesT'; % Paired t-test: the same subjects are measured under both conditions
cfg.correctm         = 'cluster'; % Cluster-based correction
cfg.clusteralpha     = 0.05; % Cluster threshold (not sure what number to use - please adjust it as you wish)
cfg.clusterstatistic = 'maxsum'; % Statistic for cluster-level comparison

cfg.minnbchan        = 2; % Minimum number of neighbors (not sure what number to use - please adjust it as you wish)
cfg.tail             = 0; % Two-tailed test
cfg.clustertail      = 0; % Two-tailed clusters
cfg.alpha            = 0.025; % Significance level
cfg.numrandomization = 100; % Number of permutations

% design matrix - I am not sure if this is correct
num_subjects = numel(SUBJECTS);
design       = zeros(2, 2 * num_subjects);
design(1, :) = [1:num_subjects 1:num_subjects]; % Subject indices
design(2, :) = [ones(1, num_subjects) 2 * ones(1, num_subjects)]; % Condition labels
cfg.design   = design;

cfg.ivar = 1; % Independent variable (condition with 3 leve;s : CWDG1, CWDG2, CWDG3) and dependent variable is the source-reconstructed brain activity.

statCWDG1vsCWDG2 = ft_sourcestatistics(cfg, sourceCWDG1, sourceCWDG2);

% find the significant results: sourceCWDG1 > sourceCWDG2
pos_clust             = find([statCWDG1vsCWDG2.posclusters(:).prob] < 0.025); % these are the positive clusters: sourceCWDG1 > sourceCWDG2
mask_pos              = ismember(statCWDG1vsCWDG2.posclusterslabelmat, pos_clust);
statCWDG1vsCWDG2.mask = mask_pos;

% Plot the significant results
cfg = [];
cfg.method       = 'ortho';
cfg.latency      =  [0.26 0.29];
cfg.funparameter = 'stat'; 
cfg.maskparameter = 'mask';
ft_sourceplot(cfg, statCWDG1vsCWDG2, mri);


