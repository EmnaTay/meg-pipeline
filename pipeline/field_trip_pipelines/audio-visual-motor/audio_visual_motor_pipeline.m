%% FieldTrip pipeline for audio-visual-motor experiment
% Author: Hadi Zaatiti <hadi.zaatiti@nyu.edu>


clear;

% Reminder of stimulus types:

% 1 is visual stimulus = ch224
% 2 is auditory stimulus = ch225
% 3 is motor button = ch226

% Read the environment variable to NYU BOX
MEG_DATA_FOLDER = getenv('MEG_DATA');


% Define paths
TASK_NAME = 'audio-visual-motor';
SYSTEM = 'meg-kit';
SUB_ID = 'sub-001';
LASER_DEVICE = 'laser-scan';


% Construct the directory path
DATA_FOLDER_PATH = fullfile(MEG_DATA_FOLDER, TASK_NAME, SUB_ID, SYSTEM);

% List all .con files with the prefix 'sub-001'
filePattern = fullfile(DATA_FOLDER_PATH, [SUB_ID,'*.con']);
conFiles = dir(filePattern);


% Display the file names
disp('Found .con files:');
for k = 1:length(conFiles)
    disp(conFiles(k).name);
end


filePattern_mrk = fullfile(DATA_FOLDER_PATH, '*.mrk');

mrkFiles = dir(filePattern_mrk);

% Construct the directory path
DATA_FOLDER_PATH_LASER = fullfile(MEG_DATA_FOLDER, TASK_NAME, SUB_ID, LASER_DEVICE);

filePattern_laser_surface = fullfile(DATA_FOLDER_PATH_LASER,  [SUB_ID,'*basic-surface.txt']);
filePattern_laser_stylus = fullfile(DATA_FOLDER_PATH_LASER,  [SUB_ID,'*stylus-points.txt']);

laser_points = dir(filePattern_laser_surface);
laser_surf = dir(filePattern_laser_stylus);


APPLY_FILTERS = false;

%%

% Initialize FieldTrip configuration
cfg = [];
cfg.coilaccuracy = 0;

% Cell array to store preprocessed data
dataList = {};

% Loop through all .con files
for k = 1:length(conFiles)
    % Construct the full path for the current .con file
    conFile = fullfile(DATA_FOLDER_PATH, conFiles(k).name);
    
    % Set the dataset in the configuration
    cfg.dataset = conFile;
    
    % Preprocess the MEG data
    fprintf('Processing file: %s\n', conFiles(k).name);
    dataList{k} = ft_preprocessing(cfg); % Store preprocessed data in the list
end

% Concatenate all preprocessed data
fprintf('Concatenating all preprocessed data...\n');
combinedData = ft_appenddata([], dataList{:});

% Display a message when concatenation is complete
disp('Data concatenation complete.');




%% Filtering data

if APPLY_FILTERS
    % Notch filter the data at 50 Hz
    cfg = [];
    cfg.bsfilter = 'yes';
    cfg.bsfreq = [49 51]; % Notch filter range
    combinedData = ft_preprocessing(cfg, combinedData);

    % Band-pass filter the data
    cfg = [];
    cfg.bpfilter = 'yes';
    cfg.bpfreq = [4 40]; % Band-pass filter range
    cfg.bpfiltord = 4;   % Filter order
    combinedData = ft_preprocessing(cfg, combinedData);
    
    disp('Filtering operations complete on combined data.');
end



%% Define trials and segmentation of the data


previewTrigger = combinedData.trial{1}(225, :);

threshold = (max(previewTrigger) + min(previewTrigger)) / 2;
    
trigger_channels = [225, 226, 227];

TRIALS_DEF = cell(length(conFiles), length(trigger_channels));
TRIALS = cell(length(conFiles), length(trigger_channels));

for fileIdx = 1:length(conFiles)

    for chIdx = 1:length(trigger_channels)
        cfg = [];
        conFile = fullfile(DATA_FOLDER_PATH, conFiles(fileIdx).name);
        cfg.dataset  = conFile;
        cfg.trialdef.eventvalue = 1; % placeholder for the conditions
        cfg.trialdef.prestim    = 0.5; % 1s before stimulus onset
        cfg.trialdef.poststim   = 1.2; % 1s after stimulus onset
        cfg.trialfun = 'ft_trialfun_general';
        cfg.trialdef.chanindx = trigger_channels(chIdx);
        cfg.trialdef.threshold = threshold;
        cfg.trialdef.eventtype = 'combined_binary_trigger'; % this will be the type of the event if combinebinary = true
        cfg.trialdef.combinebinary = 1;
        cfg.preproc.baselinewindow = [-0.2 0];
        cfg.preproc.demean     = 'yes';
    
        % Define trials for the current channel and dataset
        TRIALS_DEF{fileIdx, chIdx} = ft_definetrial(cfg);

        % Preprocess trials for the current channel and dataset
        TRIALS{fileIdx, chIdx} = ft_preprocessing(TRIALS_DEF{fileIdx, chIdx});
    end
end

%% Trials Concantenation

TRIALS_STIM = cell( length(trigger_channels),1);

for chIdx = 1:length(trigger_channels)
            cfg = [];
            TRIALS_STIM{chIdx} = ft_appenddata(cfg, TRIALS{1,chIdx}, TRIALS{2,chIdx}, TRIALS{3, chIdx});
end








%% Visual Inspection ALTL

TRIALS_STIM_REJ = cell( length(trigger_channels),1);

for tr = 1:length(TRIALS_STIM)
    
    cfg = [];
    cfg.method='summary';
    cfg.channel = {'AG*'};
    TRIALS_STIM_REJ{tr} = ft_rejectvisual(cfg, TRIALS_STIM{tr});

end

save TRIALS_STIM_REJ TRIALS_STIM_REJ



%% Averaging

AVG_TRIALS = cell( length(trigger_channels),1);

for tr = 1:length(AVG_TRIALS)

    cfg = [];

    AVG_TRIALS{tr} = ft_timelockanalysis(cfg, TRIALS_STIM_REJ{tr});

end

%% Get KIT Sensors

kit_layout = create_kit_layout(conFile);

figure('Position', [100, 100, 1000, 800]); % Adjust the width and height (1000 and 800) as needed
ft_plot_layout(kit_layout, 'box', 1);





%% Plotting in space

% for a single trial type, for each channel, average over time the trial
% and plot the average value on the helmet

% You can still see the time behavior when clicking on one sensor

for tr = 1:length(AVG_TRIALS)

    cfg = [];
    cfg.xlim = [0.05 1.2];
    cfg.colorbar = 'yes';
    cfg.layout = kit_layout;
    ft_topoplotER(cfg, AVG_TRIALS{tr});

end



