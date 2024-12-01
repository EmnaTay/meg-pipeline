% This script handles the preprocessing of the MEG data, including defining trials and data segmentation,
% cleaning the data using filters and manual visual rejection, seperating
% trials into conditions and Timelockanalysis
% Finally, the ERPs are plotted

%%
% Add FieldTrip directory to the top of the MATLAB path to fix the error of
% the 'nearest' function

% Set FieldTrip defaults
ft_defaults;

% Verify the correct 'nearest' function is being used
which nearest

%% Loading the MEG and MATLAB data

% If you have BOX app installed locally, set an environment variable with
% details
% Variable Name: MEG_DATA   Value: absolute path to 'Data' folder on box e.g.
% C:/Box/MEG/Data/
% If you do not have BOX app installed locally, then download the data
% put in a folder structure 'MEG/Data/visual_crowding_preview/' then create
% an environment variable with details
% Variable Name: MEG_DATA   Value: absolute path to 'Data' folder e.g.
% 'home/xyz/.../MEG/Data'

MEG_DATA_FOLDER = getenv('MEG_DATA');

% Set path to KIT .con file of sub-03
DATASET_PATH = [MEG_DATA_FOLDER,'visual_crowding_preview'];

%THis needs fixing to sav eproperly
SAVE_PATH = [MEG_DATA_FOLDER, 'visual_crowding_preview'];

% Get a list of all MEG data files
MEGFILES = dir(fullfile(DATASET_PATH, 'sub-*-vcp','meg-kit', 'sub-*-vcp-analysis_NR.con'));

disp(['Found ', num2str(length(MEGFILES)), ' MEG-KIT measurement .con files.']);

% Display the names of the files
for i = 1:length(MEGFILES)
    disp(MEGFILES(i).name);
end


% Get a list of all MATLAB data files in the folder matching the pattern
MATFILES = dir(fullfile(DATASET_PATH, 'sub-*-vcp','experiment-log', 'sub-*-vcp.mat'));

disp(['Found ', num2str(length(MATFILES)), ' MATLAB experiment-log .mat files.']);

% Display the names of the files
for i = 1:length(MATFILES)
    disp(MATFILES(i).name);
end

disp(' Make sure the orders in the two lists above match each other');


%%
%

segmented_data_all = cell(1, length(MEGFILES));

% Loop over each MEG data file
%for k = 1:length(MEGFILES)
%%

    % For testing purpose uncomment below
    k =1;

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
        %continue;
    end

    % Load the MATLAB data
    load_data_MAT = load(MATFILEPATH);
    data_MAT = load_data_MAT.EXP.data; % Extracting the table from the structure

    %% Preprocess data

    % Preprocess the MEG data
    cfg = [];
    cfg.dataset = confile;
    cfg.coilaccuracy = 0;
    data_MEG = ft_preprocessing(cfg);


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
    num_triggers = sum(transitions == 1);

    trigger_indices = find(transitions == 1);


    % Output the number of triggers
    fprintf('Number of triggers: %d\n', num_triggers);

    % figure
    % plot(previewTrigger)


    %% Sanity Check: Count all trigger events on all trigger channels

    % Initialize total trigger count
    total_triggers = 0;

    % Initialize structs to store trigger counts and thresholds for each channel
    trigger_counts = struct();
    thresholds = struct(); % When signal is above the threshold, this part is considered a trigger-event

    fprintf('For %s \n', subjectID);
    total_triggers2=0;
    disp(['If the value of threshold for one channel is close to zero, ' ...
        'this probably means the channel has no triggers, remove it then from the count'])
    % Loop through each channel from 225 to 231
    for ch = 225:231
        % Extract the trigger channel
        previewTrigger = data_MEG.trial{1}(ch, :);

        % Define a threshold to detect transitions
        threshold = (max(previewTrigger) + min(previewTrigger)) / 2;

        % Store the threshold for this channel
        thresholds.(sprintf('Channel_%d', ch)) = threshold;

        % Detect transitions from low to high
        transitions = diff(previewTrigger > threshold);
        difference = previewTrigger >threshold;
        counts = countSequencesWithAtLeastTwoOnes(transitions);
        fprintf('counts %d', counts);
        % Count the number of positive transitions (indicating trigger onsets)
        num_triggers = sum(transitions == 1);

        % Save the number of triggers for this channel
        trigger_counts.(sprintf('Channel_%d', ch)) = num_triggers;

        % Output the number of triggers and the threshold for this channel
        fprintf('Channel %d: Number of triggers = %d, Threshold = %.2f\n', ch, num_triggers, threshold);

        % Add to total trigger count
        total_triggers = total_triggers + num_triggers;

    end

    % Output the total number of triggers across all channels
    fprintf('Total number of triggers across all channels for %s is: %d\n', subjectID, total_triggers);

    %% Read raw confile
    % This simply returns the time series of all channels in one array
    % without any metadata

    data_raw = ft_read_data(confile);

    %% Sanity Check: If we need to plot a trigger channel and verify it

    %plot(data_raw(225,1:100000));

    %Plot with a focus on the top of the trigger
    %plot(data_raw(225,1:100000), '.-');

    %Sequence: Red, green, blue, lightblue, magenta, orange, black
    %
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

    %Make sure sequence is correct

    %% Test: define trials

    cfg = [];
    cfg.dataset  = confile;
    %cfg.trialdef.eventvalue = 1;
    cfg.trialdef.prestim    = 1;
    cfg.trialdef.poststim   = 1;
    cfg.trialfun = 'ft_trialfun_general';
    %cfg.trialdef.eventvalue     = [1 2 3 4 5 6 7]; % the values of the stimulus trigger for the three conditions LF ch225=4, WN ch226=2, HF ch227=1
    cfg.trialdef.chanindx = 225:231; % this will make the binary value either 100 LF(ch225) or WN 010(ch226) or HF 001(ch227)
    %cfg.trialdef.threshold = 0.5; % this is a meaningful value if the pulses have an amplitude of ~5 V
    %cfg.trialdef.eventtype = 'combined_binary_trigger'; % this will be the type of the event if combinebinary = true
    %cfg.trialdef.combinebinary = 1;
    % cfg.trialdef.trigshift = 2; % return the value of the combined pulse 2 samples after the on-ramp (in case of small staircases)
    cfg = ft_definetrial(cfg);

    cfg.demean = 'yes';
    cfg.channel = 'AG*';
    data = ft_preprocessing(cfg);


    %% DEBUG ONLY: Reading triggers from confile

    hdr   = ft_read_header(confile);
    %event = ft_read_event(confile, 'chanindx', 225:231, 'threshold', 1e4, 'detectflank', 'up');
    event = ft_read_event(confile, 'chanindx', 225:231, 'detectflank', 'up');

    %% Define trials and segment the data
    
    previewTrigger = data_MEG.trial{1}(227, :);

    threshold = (max(previewTrigger) + min(previewTrigger)) / 2;
    
    cfg = [];
    cfg.dataset  = confile;
    cfg.trialdef.eventvalue = 1; % placeholder for the conditions
    cfg.trialdef.prestim    = 1; % 1s before stimulus onset
    cfg.trialdef.poststim   = 0.5; % 1s after stimulus onset
    cfg.trialfun = 'ft_trialfun_general';
    cfg.trialdef.chanindx = 227;
    cfg.trialdef.threshold = threshold;
    cfg.trialdef.eventtype = 'combined_binary_trigger'; % this will be the type of the event if combinebinary = true
    cfg.trialdef.combinebinary = 1;
    cfg = ft_definetrial(cfg);

    if size(cfg.trl, 1) > 300
        cfg.trl = cfg.trl(1:300, :);
    end

    % Update the fourth column (eventvalue placeholder) of cfg.trl with the conditions
    cfg.trl(:, 4) = data_MAT.crowding;


    % Segment the data based on the defined trials
    % Maybe this is not needed when no filter are applied yet
    segmented_data = ft_preprocessing(cfg);

    
    %% Cleaning: Filtering the data using bandpass and notch filter

    % Band-pass filter the data
    cfg = [];
    cfg.bpfilter = 'yes';
    cfg.bpfreq = [4 40]; % Band-pass filter range
    cfg.bpfiltord = 4;    % Filter order
    data_bp = ft_preprocessing(cfg, segmented_data);

    % Notch filter the data at 50 Hz
    cfg = [];
    cfg.bsfilter = 'yes';
    cfg.bsfreq = [49 51]; % Notch filter range
    data_filtered = ft_preprocessing(cfg, data_bp);


    %% Plot bad channel

    % Identify the MEG channels (assuming MEG channels are 1 to 224)
    % Channel 92 is broken sensor should be excluded
    % Plot of channel 92
    
    cfg = [];
    cfg.channel = data_MEG.label{92};  
    %cfg.xlim = [data_MEG.time{1}(1) data_MEG.time{1}(end)];  % This sets the x-axis to cover the entire time range
    cfg.xlim = 'maxmin';  % Automatically set x-axis limits based on the data range
    cfg.ylim = 'maxmin';  % Automatically set y-axis limits based on the data range
    
    % Shows that at 10^-26 scale 
    ft_singleplotER(cfg, data_MEG);
    

    %% Plot good channel

    % Identify the MEG channels (assuming MEG channels are 1 to 224)
    % Channel 92 is broken sensor should be excluded
    % Plot of channel 92
    
    cfg = [];
    cfg.channel = data_MEG.label{91};  
    %cfg.xlim = [data_MEG.time{1}(1) data_MEG.time{1}(end)];  % This sets the x-axis to cover the entire time range
    cfg.xlim = 'maxmin';  % Automatically set x-axis limits based on the data range
    cfg.ylim = 'maxmin';  % Automatically set y-axis limits based on the data range
    

    ft_singleplotER(cfg, data_MEG);
    
    %% Cleaning: Inspect and exclude trials for artefacts 
    % MEG channels
    % meg_channels = 1:208;
    %Corrected
    meg_channels = setdiff(1:208, 92);

    % Use ft_databrowser for interactive visualization excluding trigger channels
    cfg_reject = [];
    cfg_reject.method   = 'summary';
    cfg_reject.ylim = [-1e-12 1e-12];  % Set appropriate ylim for MEG channels
    cfg_reject.megscale = 1;  % Scaling factor for MEG channels
    cfg_reject.channel = meg_channels;  % Include only MEG channels
    segmented_data_clean = ft_rejectvisual(cfg_reject, data_filtered);

    segmented_data_all{k} = segmented_data_clean;


    %% Cleaning: ICA

    

    %% separate the trials into the conditions

    cfg=[];

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
    avgCWDG1 = ft_timelockanalysis(cfg, dataCrowding1);
    avgCWDG2 = ft_timelockanalysis(cfg, dataCrowding2);
    avgCWDG3 = ft_timelockanalysis(cfg, dataCrowding3);

    % Save the results for the current subject
    subjectResultsFolder = fullfile(SAVE_PATH, subjectID);
    if ~exist(subjectResultsFolder, 'dir')
        mkdir(subjectResultsFolder);
    end

    save(fullfile(subjectResultsFolder, sprintf('%s_avgCWDG1.mat', subjectID)), 'avgCWDG1');
    save(fullfile(subjectResultsFolder, sprintf('%s_avgCWDG2.mat', subjectID)), 'avgCWDG2');
    save(fullfile(subjectResultsFolder, sprintf('%s_avgCWDG3.mat', subjectID)), 'avgCWDG3');

%% Plot all ERPs in sensor space
    cfg = [];
    cfg.showlabels = 'no';
    cfg.fontsize = 6;
    %cfg.layout = 'CTF151_helmet.mat';
    cfg.baseline = [-0.2 0];
    cfg.xlim = [-0.2 1.0];
    cfg.ylim = [-3e-13 3e-13];
    ft_multiplotER(cfg, avgCWDG1, avgCWDG2, avgCWDG3);
    title(sprintf('ERP Activity in sensor space: %s', subjectID), 'Interpreter', 'none');

    saveas(gcf, fullfile(subjectResultsFolder, sprintf('%s_ERP_Sensor_Space.png', subjectID)));


    % Plot all ERPs from a specific channel
    cfg = [];
    cfg.xlim = [-0.2 1.0];
    cfg.ylim = [-1e-13 3e-13];
    cfg.channel = 'AG001';
    ft_singleplotER(cfg, avgCWDG1, avgCWDG2, avgCWDG3);
    title(sprintf('ERP Activity of Subject: %s', subjectID), 'Interpreter', 'none');

    saveas(gcf, fullfile(subjectResultsFolder, sprintf('%s_ERP.png', subjectID)));

    % Topographic plot of the ERP
    cfg = [];
    cfg.xlim =  [0.3 0.5];
    cfg.colorbar = 'yes';
    %cfg.layout = 'CTF151_helmet.mat';
    ft_topoplotER(cfg, avgCWDG1);
    title(sprintf('Topographic plot of condition 1: %s', subjectID), 'Interpreter', 'none');
    saveas(gcf, fullfile(subjectResultsFolder, sprintf('%s_Topographic_plot_cwdg_1.png', subjectID)));



    cfg = [];
    cfg.xlim = [0.3 0.5];
    cfg.colorbar = 'yes';
    %cfg.layout = 'CTF151_helmet.mat';
    ft_topoplotER(cfg, avgCWDG2);
    title(sprintf('Topographic plot of condition 2: %s', subjectID), 'Interpreter', 'none');
    saveas(gcf, fullfile(subjectResultsFolder, sprintf('%s_Topographic_plot_cwdg_2.png', subjectID)));



    cfg = [];
    cfg.xlim = [0.3 0.5];
    cfg.colorbar = 'yes';
    %cfg.layout = 'CTF151_helmet.mat';
    ft_topoplotER(cfg, avgCWDG3);
    title(sprintf('Topographic plot of condition 3: %s', subjectID), 'Interpreter', 'none');
    saveas(gcf, fullfile(subjectResultsFolder, sprintf('%s_Topographic_plot_cwdg_3.png', subjectID)));



    %% Do a constrast analysis High crowding - No Crowding

    

%% FREQUENCY ANALYSIS

% Frequency Analysis using Hanning window

cfg              = [];
cfg.output       = 'pow';
cfg.channel      = 'AG*';
cfg.method       = 'mtmconvol';
cfg.taper        = 'hanning';
cfg.foi          = 12:2:30;                         % analysis 2 to 30 Hz in steps of 2 Hz
cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;   % length of time window = 0.5 sec
cfg.toi          = -1:0.05:0.5;                  % time window "slides" from -0.5 to 1.5 sec in steps of 0.05 sec (50 ms)
TFRhann = ft_freqanalysis(cfg, dataCrowding1);

% Plot 
cfg = [];
cfg.baseline     = [-0.5 -0.1];
cfg.baselinetype = 'absolute';
cfg.zlim         = [-2.5e-27 2.5e-27];
cfg.showlabels   = 'yes';
% cfg.layout       = 'CTF151_helmet.mat';
figure
set(gcf, 'Position', [200, 100, 1500, 1000]);  % Adjust the size (optional)
ft_multiplotTFR(cfg, TFRhann);
title('Frequency Analysis using Hanning; Cond1');
h = gcf;  % gcf gets the handle of the current figure
saveas(h, 'Frequ_Hanning_Cond1.png');


% Frequency Analysis using Wavelet

cfg = [];
cfg.channel    = 'AG*';
cfg.method     = 'wavelet';
cfg.width      = 15;
cfg.output     = 'pow';
cfg.foi        = 12:2:30;
cfg.toi        = -1:0.05:0.5;
TFRwave = ft_freqanalysis(cfg, dataCrowding1);

% plot
cfg = [];
cfg.baseline     = [-0.5 -0.1];
cfg.baselinetype = 'absolute';
cfg.zlim         = [-2e-25 2e-25];
cfg.showlabels   = 'yes';
% cfg.layout       = 'CTF151_helmet.mat';
cfg.colorbar     = 'yes';
figure
ft_multiplotTFR(cfg, TFRwave)
set(gcf, 'Position', [200, 100, 1500, 1000]);  % Adjust the size (optional)
title('Frequency Analysis using Wavelet; Cond1');
h = gcf;  % gcf gets the handle of the current figure
saveas(h, 'Frequ_Wavelet_Cond1.png');



%end

