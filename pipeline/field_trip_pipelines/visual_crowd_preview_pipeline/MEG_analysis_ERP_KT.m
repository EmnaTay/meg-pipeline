ft_defaults

%% configure paths

MEG_DATA_FOLDER = getenv('MEG_DATA');

% Set path to KIT .con file of sub-03
DATASET_PATH = [MEG_DATA_FOLDER,'visual_crowding_preview'];

% This needs fixing to save properly
SAVE_PATH = [MEG_DATA_FOLDER, 'visual_crowding_preview'];

%% MEGFILES

% Get a list of all MEG data files
MEGFILES = dir(fullfile(DATASET_PATH, 'sub-*-vcp','meg-kit', 'sub-*-vcp-analysis_NR.con'));

disp(['Found ', num2str(length(MEGFILES)), ' MEG-KIT measurement .con files.']);

% Display the names of the files
for i = 1:length(MEGFILES)
    disp(MEGFILES(i).name);
end

%% MATFILES

% Get a list of all MATLAB data files in the folder matching the pattern
MATFILES = dir(fullfile(DATASET_PATH, 'sub-*-vcp','experiment-log', 'sub-*-vcp.mat'));

disp(['Found ', num2str(length(MATFILES)), ' MATLAB experiment-log .mat files.']);

% Display the names of the files
for i = 1:length(MATFILES)
    disp(MATFILES(i).name);
end

disp(' Make sure the orders in the two lists above match each other');

%% data_MEG & data_MAT

for k = 1
    % Get the current MEG data file name   
    confile = fullfile(MEGFILES(k).folder, MEGFILES(k).name);
    
    [~, filename, ~] = fileparts(MEGFILES(k).name);
    
    % Extract the subject identifier from the MEG file name
    match = regexp(filename, 'sub-(\d+)-vcp', 'tokens');
    
    % Extract the matched number
    if ~isempty(match)
        numericalPart = match{1}{1};
    else
        disp(['ID for subject file', confile, 'not found']);
    end
    
    subjectID = sprintf('Subject %s', numericalPart); % Format to 'Subject ###'
    
    % Construct the corresponding MATLAB data file path
    MATFILENAME = sprintf('sub-%s-vcp.mat', numericalPart);
    
    MATFILEPATH = fullfile(MATFILES(k).folder, MATFILENAME);
    
    % Check if the MATLAB data file exists in the list of matFiles
    if ~isfile(MATFILEPATH)
        fprintf('MATLAB data file not found for subject: %s\n', subjectID);
    end
end

% Load the MATLAB data
load_data_MAT = load(MATFILEPATH);
data_MAT = load_data_MAT.EXP.data; % Extracting the table from the structure

% Preprocess data without defining trials
cfg              = [];
cfg.dataset      = confile;
cfg.coilaccuracy = 0;
data_MEG         = ft_preprocessing(cfg); % KT: Sensor AG092 missing why? Why coilori and coilpos are 2*207 while we have magnetometers?

%% Sanity Check: If we need to plot a trigger channel and verify it

% way 1
% Sequence: Red, green, blue, lightblue, magenta, orange, black
figure
hold on
plot(data_raw(225, :), 'r');   % Red
plot(data_raw(226, :), 'g');   % Green
plot(data_raw(227, :), 'b');   % Blue
plot(data_raw(228, :), 'c');   % Cyan
plot(data_raw(229, :), 'm');   % Magenta
plot(data_raw(230, :), 'y');   % Yellow
plot(data_raw(231, :), 'k');   % Black
hold off
% Make sure sequence is correct





%% DEBUG ONLY: Reading triggers from confile

hdr      = ft_read_header(confile);
type = ft_chantype(hdr); % meggrad = meg axial gradiometers
event227 = ft_read_event(confile, 'chanindx', 227); % only 56 times is '227' found. FT does not detect well the triggers
event231 = ft_read_event(confile, 'chanindx', 231); % only 226 times is '231' found


%% Remind that in the design of the experiment we had defined: (in MATLAB indexing not the MEG reference)

% - trigger channel 225: beginning of the overall experiment.
% - trigger channel 226: each display of the fixation point.
% - trigger channel 227: display of the preview image.
% - trigger channel 228: display of the cue (fixation point turns green).
% - trigger channel 229: saccade detection.
% - trigger channel 230: display of the target image.
% - trigger channel 231: display of the question image.

%% Output the number of triggers on channel 227 for preview event
% Number of triggers should corespond to the number of trials in the
% experiment

% Extract the trigger channel (channel 227)
previewTrigger = data_MEG.trial{1}(227, :);

% Define a threshold to detect transitions
% This threshold should only be used when we are sure that the channel
% contains atleast one trigger, if not the number of triggers is
% incorrect
threshold = (max(previewTrigger) + min(previewTrigger)) / 2;

% Detect transitions from low to high
transitions = diff(previewTrigger > threshold);

% Count the number of positive transitions (indicating trigger onsets)
num_triggers = sum(transitions == 1); % = 300

% Output the number of triggers
fprintf('Number of triggers: %d\n', num_triggers);

figure;
plot(previewTrigger)

%% Define trials and preprocess the data

cfg = [];
cfg.dataset                = confile;
cfg.trialdef.eventtype     = 'combined_binary_trigger'; 
cfg.trialdef.eventvalue    = 1; 
cfg.trialdef.prestim       = 1; 
cfg.trialdef.poststim      = 0.5; 
cfg.trialdef.chanindx      = 227;
cfg.trialdef.threshold     = threshold;
cfg.trialdef.combinebinary = 1;
cfg.trialfun               = 'ft_trialfun_general';
cfg = ft_definetrial(cfg);

% Update the fourth column (eventvalue placeholder) of cfg.trl with the conditions
cfg.trl(:, 4) = data_MAT.crowding;


% Segment the data based on the defined trials
% Maybe this is not needed when no filter are applied yet
segmented_data = ft_preprocessing(cfg);

%% plot segmented data

meg_channels = setdiff(1:208, 92);

cfg =[];
cfg.ylim = [-1e-12, 1e-12];
cfg.channel  = meg_channels;  % Include only MEG channels
cfg.viewmode = 'butterfly';
ft_databrowser(cfg, segmented_data)

%% Cleaning: Inspect and exclude trials for artefacts 

meg_channels = setdiff(1:208, 92);

cfg                  = [];
cfg.method           = 'summary';
cfg.channel          = meg_channels;  % Include only MEG channels
segmented_data_clean = ft_rejectvisual(cfg, segmented_data); % I set threshold 7e-25. I remove only trials, I kept all the channels

 %% separate the trials into the conditions

cfg        = [];

cfg.trials = (segmented_data_clean.trialinfo==1);
dataCrowding1 = ft_selectdata(cfg, segmented_data_clean);

cfg.trials = (segmented_data_clean.trialinfo==2);
dataCrowding2 = ft_selectdata(cfg, segmented_data_clean);

cfg.trials = (segmented_data_clean.trialinfo==3);
dataCrowding3 = ft_selectdata(cfg, segmented_data_clean);

% Visualize the first trial of channel 20
% figure
% plot(dataCrowding1.time{1}, dataCrowding1.trial{1}(20,:))

 %% Timelockanalysis

cfg = [];
cfg.covariance       = 'yes'; % for beamformer
avgCWDG1 = ft_timelockanalysis(cfg, dataCrowding1);
avgCWDG2 = ft_timelockanalysis(cfg, dataCrowding2);
avgCWDG3 = ft_timelockanalysis(cfg, dataCrowding3);


%% save

for k = 1
    % Define the subject ID based on k
    subject_id = sprintf('sub-%03d-vcp', k);
    
    % Define the folder path
    derivatives_folder = fullfile(SAVE_PATH, subject_id, 'derivatives');
   
    % Save the data files in the defined folder
    save(fullfile(derivatives_folder, 'avgCWDG1.mat'), 'avgCWDG1');
    save(fullfile(derivatives_folder, 'avgCWDG2.mat'), 'avgCWDG2');
    save(fullfile(derivatives_folder, 'avgCWDG3.mat'), 'avgCWDG3');
end

load(fullfile(derivatives_folder, 'avgCWDG1.mat'), 'avgCWDG1');
load(fullfile(derivatives_folder, 'avgCWDG2.mat'), 'avgCWDG2');
load(fullfile(derivatives_folder, 'avgCWDG3.mat'), 'avgCWDG3'); 

% avgCWDG1: high crowding
% avgCWDG2: medium crowding
% avgCWDG3: no crowding

%% Plot all ERPs in sensor space

meg_channels = setdiff(1:208, 92);

cfg = [];
cfg.showlabels = 'yes';
cfg.channel          = meg_channels;  % Include only MEG channels
cfg.linecolor = [0 0 1; 0 1 0; 1 0 0]; % Blue, Green, Red
ft_multiplotER(cfg, avgCWDG1, avgCWDG2, avgCWDG3); % it automatically creates layout for yokogawa208 system
title(sprintf('ERP Activity in sensor space: %s', subjectID), 'Interpreter', 'none');

% saveas(gcf, fullfile(derivatives_folder, sprintf('%s_ERP_Sensor_Space.png', subjectID)));


% Plot all ERPs from a specific channel
cfg = [];
cfg.xlim =  [0.2 0.3];
% cfg.ylim = [-1e-13 3e-13];
cfg.channel = {'AG080', 'AG131', 'AG142', 'AG153', 'AG169', 'AG176'};
cfg.linecolor = [0 0 1; 0 1 0; 1 0 0]; % Blue, Green, Red
ft_singleplotER(cfg, avgCWDG1, avgCWDG2, avgCWDG3);
title(sprintf('ERP Activity of Subject: %s', subjectID), 'Interpreter', 'none');

% saveas(gcf, fullfile(derivatives_folder, sprintf('%s_ERP.png', subjectID)));

% Topographic plot of the ERP
cfg = [];
cfg.xlim =  [0.26 0.29];
cfg.colorbar = 'yes';
%cfg.layout = 'CTF151_helmet.mat';
ft_topoplotER(cfg, avgCWDG1);
title(sprintf('Topographic plot of condition 1: %s', subjectID), 'Interpreter', 'none');

% saveas(gcf, fullfile(derivatives_folder, sprintf('%s_Topographic_plot_cwdg_1.png', subjectID)));



cfg = [];
cfg.xlim = [0.3 0.5];
cfg.colorbar = 'yes';
%cfg.layout = 'CTF151_helmet.mat';
ft_topoplotER(cfg, avgCWDG2);
title(sprintf('Topographic plot of condition 2: %s', subjectID), 'Interpreter', 'none');

% saveas(gcf, fullfile(derivatives_folder, sprintf('%s_Topographic_plot_cwdg_2.png', subjectID)));



cfg = [];
cfg.xlim = [0.3 0.5];
cfg.colorbar = 'yes';
%cfg.layout = 'CTF151_helmet.mat';
ft_topoplotER(cfg, avgCWDG3);
title(sprintf('Topographic plot of condition 3: %s', subjectID), 'Interpreter', 'none');

% saveas(gcf, fullfile(derivatives_folder, sprintf('%s_Topographic_plot_cwdg_3.png', subjectID)));