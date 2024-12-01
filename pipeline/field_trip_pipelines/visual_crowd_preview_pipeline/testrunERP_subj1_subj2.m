% This script handles the preprocessing of the MEG data, including defining trials and data segmentation,
% cleaning the data using filters and manual visual rejection, seperating
% trials into conditions and Timelockanalysis
% Finally, the ERPs are plotted as well as frequency analysis

%%
% This Script works on subj. 1 and subj. 2. 
% It does manual trial definition but matlab conditions and MEG-triggers
% are perfectly aligned.
% Subj.1 is good.
% Subj.2 is good but ERP is weak.

clear all;
%%
% Add FieldTrip directory to the top of the MATLAB path to fix the error of
% the 'nearest' function
addpath('C:\Users\tasni\AppData\Roaming\MathWorks\MATLAB Add-Ons\Collections\FieldTrip\utilities');

% Set FieldTrip defaults
ft_defaults;

% Verify the correct 'nearest' function is being used
which nearest

%% Loading the MEG and MATLAB data

% Define the paths to the MEG data and MATLAB data folders
megDataFolder = 'MEG data';
matlabDataFolder = 'MATLAB Data';
resultsFolder = 'Averaging Results';

% Get a list of all MEG data files in the folder matching the specific pattern
megFiles = dir(fullfile(megDataFolder, 'Sub_002_01_vcp.con'));

% Get a list of all MATLAB data files in the folder matching the specific pattern
matFiles = dir(fullfile(matlabDataFolder, 'Sub_002_vcp.mat'));


segmented_data_all = cell(1, length(megFiles));

% Loop over each MEG data file
for k = 1:length(megFiles)
    % Get the current MEG data file name
    confile = fullfile(megDataFolder, megFiles(k).name);

    % Extract the subject identifier from the MEG file name
    [~, filename, ~] = fileparts(megFiles(k).name);
    numericalPart = filename(5:7); % Extract the numerical part, assuming 'Sub_###'
    subjectID = sprintf('Subject %s', numericalPart); % Format to 'Subject ###'

    % Construct the corresponding MATLAB data file path
    matFileName = sprintf('Sub_%s_vcp.mat', numericalPart);
    matFilePath = fullfile(matlabDataFolder, matFileName);

    % Check if the MATLAB data file exists in the list of matFiles
    if ~isfile(matFilePath)
        fprintf('MATLAB data file not found for subject: %s\n', subjectID);
        continue;
    end

    % Load the MATLAB data
    load_data_MAT = load(matFilePath);
    data_MAT = load_data_MAT.EXP.data; % Extracting the table from the structure

    % Preprocess the MEG data
    cfg = [];
    cfg.dataset = confile;
    cfg.coilaccuracy = 0;
    data_MEG = ft_preprocessing(cfg);

    %% Output the number of triggers on channel 227 for preview event
    % Number of triggers should corespond to the number of trials in the
    % experiment

    % Extract the trigger channel (channel 227)
    previewTrigger = data_MEG.trial{1}(227, :);
    time = data_MEG.time{1};

    figure
    plot(time, previewTrigger)

    % Define a threshold to detect transitions
    threshold = (max(previewTrigger) + min(previewTrigger)) / 2;

    % Detect transitions from low to high
    transitions = diff(previewTrigger > threshold);

    % Count the number of positive transitions (indicating trigger onsets)
    num_triggers = sum(transitions == 1);

    % Find the indices where a transition (positive) occurs
    trigger_indices = find(transitions == 1);  % Indices of trigger onsets

    % Extract the corresponding times for each trigger
    trigger_times_seconds = time(trigger_indices);  % Corresponding times for each trigger

    % Output the number of triggers
    fprintf('Number of triggers: %d\n', num_triggers);



    %% Manual trial definition

    % FIXING/IDENTIFYING THE TRIGGERS

    conditions = data_MAT.crowding;  % Extract the condition column
    condition_timestamps = data_MAT.previewOnsetTime;

    % First time point for each dataset
    first_condition_time = condition_timestamps(1);  % The first condition is at around 800 seconds
    first_trigger_time = trigger_times_seconds(1);      % The first trigger is at around 23 seconds

    % Shift both time vectors to normalize them to the same starting point
    % This will set the first event to 0 seconds
    normalized_condition_times = condition_timestamps - first_condition_time;
    normalized_trigger_times = trigger_times_seconds - first_trigger_time;
    normalized_trigger_times = normalized_trigger_times';

    % Check the triggers and conditions before removing anything
    figure;
    % Plot the normalized trigger times (as red circles)
    scatter(normalized_trigger_times, ones(size(normalized_trigger_times)), 50, 'yo', 'filled', 'DisplayName', 'Trigger Onsets');
    hold on;
    plot(normalized_condition_times(conditions == 1), ones(sum(conditions == 1), 1), 'ro', 'DisplayName', 'Condition 1');
    % Plot for condition 2
    plot(normalized_condition_times(conditions == 2), ones(sum(conditions == 2), 1), 'kx', 'DisplayName', 'Condition 2');
    % Plot for condition 3
    plot(normalized_condition_times(conditions == 3), ones(sum(conditions == 3), 1), 'bo', 'DisplayName', 'Condition 3');
    % Customize the plot
    xlabel('Time (seconds)');  % X-axis label
    ylabel('Trigger Signal');  % Y-axis label
    title('Extra MEG Trigger Signal and Trigger Onsets');
    legend('show');  % Show legend
    grid on;  % Add a grid for better readability


    %% removing extra triggers

    time_threshold = 0.1;  % Adjust based on timing precision

    % Initialize an array for storing matched triggers
    num_conditions = length(normalized_condition_times);
    matched_triggers = NaN(num_conditions, 1);  % Preallocate

    % Iterate through each condition to find the corresponding trigger
    for i = 1:num_conditions
        % Find the trigger closest to this condition within the time threshold
        [min_diff, closest_trigger_idx] = min(abs(normalized_trigger_times - normalized_condition_times(i)));

        if min_diff <= time_threshold
            % If the closest trigger is within the time threshold, consider it a match
            matched_triggers(i) = normalized_trigger_times(closest_trigger_idx);
        end
    end

    % Now find the triggers that weren't matched to any conditions (extra triggers)
    extra_triggers = setdiff(normalized_trigger_times, matched_triggers);

    % Filter out extra triggers from the normalized_trigger_times array
    filtered_triggers = setdiff(normalized_trigger_times, extra_triggers);

    % check if triggers and conditions align properly after removing
    figure;
    % Plot the normalized trigger times (as red circles)
    scatter(matched_triggers, ones(size(matched_triggers)), 50, 'yo', 'filled', 'DisplayName', 'Trigger Onsets');
    hold on;
    plot(normalized_condition_times(conditions == 1), ones(sum(conditions == 1), 1), 'ro', 'DisplayName', 'Condition 1');
    % Plot for condition 2
    plot(normalized_condition_times(conditions == 2), ones(sum(conditions == 2), 1), 'kx', 'DisplayName', 'Condition 2');
    % Plot for condition 3
    plot(normalized_condition_times(conditions == 3), ones(sum(conditions == 3), 1), 'bo', 'DisplayName', 'Condition 3');
    % Customize the plot
    xlabel('Time (seconds)');  % X-axis label
    ylabel('Trigger Signal');  % Y-axis label
    title('Correct MEG Trigger Signal and Normalized Trigger Onsets');
    legend('show');  % Show legend
    grid on;  % Add a grid for better readability

    %%

    unnormalized_trigger_times = matched_triggers + first_trigger_time;

    data_MEG.trial{1}(227, :) = 0;


    % Step 3: Find the nearest time point in data_MEG.time{1} for each denormalized trigger time
    for i = 1:length(unnormalized_trigger_times)
        % Find the index in data_MEG.time{1} that is closest to the current unnormalized trigger time
        [~, trigger_idx] = min(abs(data_MEG.time{1} - unnormalized_trigger_times(i)));

        % Set the trigger value at the identified index
        data_MEG.trial{1}(227, trigger_idx) = 1;  % Set the trigger value to 1 (or the desired value)
    end

    figure;
    plot(data_MEG.time{1}, data_MEG.trial{1}(227, :));  % Plot the modified trigger channel
    title('Updated Trigger Channel');
    xlabel('Time (seconds)');
    ylabel('Trigger Signal');


    %% Verify new number of triggers

    % Extract the trigger channel (channel 227)
    newpreviewTrigger = data_MEG.trial{1}(227, :);

    % Define a threshold to detect transitions
    newthreshold = (max(newpreviewTrigger) + min(newpreviewTrigger)) / 2;

    % Detect transitions from low to high
    newtransitions = diff(newpreviewTrigger > newthreshold);
    new_trigger_indices = find(newtransitions == 1);

    % Verify the number of triggers
    num_new_triggers = length(new_trigger_indices);
    fprintf('Number of detected new triggers: %d\n', num_new_triggers);

    % Count the number of positive transitions (indicating trigger onsets)
    newnum_triggers = sum(newtransitions == 1);

    % Output the number of triggers
    fprintf('Number of triggers: %d\n', newnum_triggers);

    %%

    % Define pre-stimulus and post-stimulus times in samples
    prestim_samples = 1 * data_MEG.fsample;  % 1 second before the trigger (in samples)
    poststim_samples = 0.5 * data_MEG.fsample;  % 0.5 seconds after the trigger (in samples)

    % Initialize the trial structure (trl matrix)
    trl = [];

    % Loop through each trigger index and create a trial around it
    for i = 1:num_new_triggers
        trigger_sample = new_trigger_indices(i);  % The sample index of the trigger

        % Define the trial start and end in samples
        trial_start = trigger_sample - prestim_samples;
        trial_end = trigger_sample + poststim_samples;
        trial_offset = -prestim_samples;  % Offset to align the trial to stimulus onset (0)

        % Add this trial to the trial matrix (start, end, offset)
        trl = [trl; trial_start, trial_end, trial_offset];
    end

    % Verify the number of trials created
    fprintf('Number of trials created: %d\n', size(trl, 1));


    cfg = [];
    cfg.trl = trl;  % Use the manually defined trial structure
    cfg.trl(:, 4) = data_MAT.crowding;
    segmented_data = ft_redefinetrial(cfg, data_MEG);  % Segment the data based on the new trials


    %%

% Define time axis based on pre- and post-stimulus times in seconds
sampling_rate = data_MEG.fsample;  % Sampling rate of the data
trial_length = size(segmented_data.trial{1}, 2);  % Number of samples per trial (e.g., 1051)
time_axis = linspace(-prestim_samples / sampling_rate, poststim_samples / sampling_rate, trial_length);

% Loop through each trial and plot the first channel
figure;
hold on;  % Hold on to plot all trials in the same figure

for i = 1:length(segmented_data.trial)
    % Extract the first channel of the current trial
    first_channel_data = segmented_data.trial{i}(1, :);  % 1st row of each trial (channel 1)
    
    % Plot the first channel for this trial
    plot(time_axis, first_channel_data);
end

% Customize the plot
xlabel('Time (s)');
ylabel('Amplitude');
title('First Channel of Each Trial');
hold off;



    %% Cleaning: Inspect and exclude trials for artefacts

    meg_channels = setdiff(1:208, 92);

    % Use ft_databrowser for interactive visualization excluding trigger channels
    cfg_reject = [];
    cfg_reject.method   = 'summary';
    cfg_reject.ylim = [-1e-12 1e-12];  % Set appropriate ylim for MEG channels
    cfg_reject.megscale = 1;  % Scaling factor for MEG channels
    cfg_reject.channel = meg_channels;  % Include only MEG channels
    segmented_data_clean = ft_rejectvisual(cfg_reject, segmented_data);

    % segmented_data_all{k} = segmented_data_clean;


    %% Baseline correction
% Baseline correction on each trial before averaging
cfg = [];
cfg.demean = 'yes';              % Enable baseline correction
cfg.baselinewindow = [-1 0];     % Define baseline window (1s before stimulus onset)
segmented_data_bc = ft_preprocessing(cfg, segmented_data_clean);


    %% Cleaning: Filtering the data using bandpass and notch filter

    % Band-pass filter the data
    cfg = [];
    cfg.bpfilter = 'yes';
    cfg.bpfreq = [4 40]; % Band-pass filter range
    cfg.bpfiltord = 4;    % Filter order
    data_bp = ft_preprocessing(cfg, segmented_data_bc);

    % Notch filter the data at 50 Hz
    cfg = [];
    cfg.bsfilter = 'yes';
    cfg.bsfreq = [49 51]; % Notch filter range
    data_filtered = ft_preprocessing(cfg, data_bp);

    % Notch filter the data at 62 Hz
    % cfg = [];
    % cfg.bsfilter = 'yes';
    % cfg.bsfreq = [61 63]; % Notch filter range
    % data_filtered_60hz = ft_preprocessing(cfg, data_filtered);


    %% Cleaning: ICA



    %% separate the trials into the conditions

    cfg=[];

    cfg.trials = (data_filtered.trialinfo==1);
    dataCrowding1 = ft_selectdata(cfg, data_filtered);

    cfg.trials = (data_filtered.trialinfo==2);
    dataCrowding2 = ft_selectdata(cfg, data_filtered);

    cfg.trials = (data_filtered.trialinfo==3);
    dataCrowding3 = ft_selectdata(cfg, data_filtered);

    % % Visualize the first trial of channel 20
    % figure
    % plot(dataCrowding1.time{1}, dataCrowding1.trial{1}(20,:))


    %% Timelockanalysis

        cfg = [];
        avgCWDG1 = ft_timelockanalysis(cfg, dataCrowding1);
        avgCWDG2 = ft_timelockanalysis(cfg, dataCrowding2);
        avgCWDG3 = ft_timelockanalysis(cfg, dataCrowding3);

        % Save the results for the current subject
        % subjectResultsFolder = fullfile(resultsFolder, subjectID);
        % if ~exist(subjectResultsFolder, 'dir')
        %     mkdir(subjectResultsFolder);
        % end

        % save(fullfile(subjectResultsFolder, sprintf('%s_avgCWDG1.mat', subjectID)), 'avgCWDG1');
        % save(fullfile(subjectResultsFolder, sprintf('%s_avgCWDG2.mat', subjectID)), 'avgCWDG2');
        % save(fullfile(subjectResultsFolder, sprintf('%s_avgCWDG3.mat', subjectID)), 'avgCWDG3');


        %% Plot all ERPs in sensor space
        cfg = [];
        cfg.showlabels = 'yes';
        cfg.fontsize = 6;
        %cfg.layout = 'CTF151_helmet.mat';
        ft_multiplotER(cfg, avgCWDG1);
        title(sprintf('ERP Activity in sensor space: %s', subjectID), 'Interpreter', 'none');

    % %     saveas(gcf, fullfile(subjectResultsFolder, sprintf('%s_ERP_Sensor_Space.png', subjectID)));


        % Plot all ERPs from a specific channel
        cfg = [];
        cfg.xlim = [-0.2 1.0];
        cfg.ylim = [-1e-13 3e-13];
        cfg.channel = 'AG150';
        ft_singleplotER(cfg, avgCWDG1, avgCWDG2, avgCWDG3);
        title(sprintf('ERP Activity of Subject: %s', subjectID), 'Interpreter', 'none');

    %     saveas(gcf, fullfile(subjectResultsFolder, sprintf('%s_ERP.png', subjectID)));
    %
    %     % Topographic plot of the ERP of condition 1
    %     cfg = [];
    %     cfg.xlim =  [0.3 0.5];
    %     cfg.colorbar = 'yes';
    %     %cfg.layout = 'CTF151_helmet.mat';
    %     ft_topoplotER(cfg, avgCWDG1);
    %     title(sprintf('Topographic plot of condition 1: %s', subjectID), 'Interpreter', 'none');
    %     saveas(gcf, fullfile(subjectResultsFolder, sprintf('%s_Topographic_plot_cwdg_1.png', subjectID)));
    %
    %
    %     % Topographic plot of the ERP of condition 2
    %     cfg = [];
    %     cfg.xlim = [0.3 0.5];
    %     cfg.colorbar = 'yes';
    %     %cfg.layout = 'CTF151_helmet.mat';
    %     ft_topoplotER(cfg, avgCWDG2);
    %     title(sprintf('Topographic plot of condition 2: %s', subjectID), 'Interpreter', 'none');
    %     saveas(gcf, fullfile(subjectResultsFolder, sprintf('%s_Topographic_plot_cwdg_2.png', subjectID)));
    %
    %
    %     % Topographic plot of the ERP of condition 3
    %     cfg = [];
    %     cfg.xlim = [0.3 0.5];
    %     cfg.colorbar = 'yes';
    %     %cfg.layout = 'CTF151_helmet.mat';
    %     ft_topoplotER(cfg, avgCWDG3);
    %     title(sprintf('Topographic plot of condition 3: %s', subjectID), 'Interpreter', 'none');
    %     saveas(gcf, fullfile(subjectResultsFolder, sprintf('%s_Topographic_plot_cwdg_3.png', subjectID)));
    %
    %     cfg = [];
    %     cfg.xlim = [-0.1 : 0.1 : 0.5];
    %     cfg.colorbar = 'yes';
    %     %cfg.layout = 'CTF151_helmet.mat';
    %     ft_topoplotER(cfg, avgCWDG3);
    %     sgtitle(sprintf('Topographic plots of condition 3: %s', subjectID), 'Interpreter', 'none');
    %     saveas(gcf, fullfile(subjectResultsFolder, sprintf('%s_Topographic_plots_cwdg_3.png', subjectID)));
    %
    %
    % %% FREQUENCY ANALYSIS
    %
    % cfg              = [];
    % cfg.output       = 'pow';
    % cfg.channel      = 'AG*';
    % cfg.method       = 'mtmconvol';
    % cfg.taper        = 'hanning';
    % cfg.foi          = 12:2:30;                         % analysis 2 to 30 Hz in steps of 2 Hz
    % cfg.t_ftimwin    = ones(length(cfg.foi),1).*0.5;   % length of time window = 0.5 sec
    % cfg.toi          = -1:0.05:0.5;                  % time window "slides" from -0.5 to 1.5 sec in steps of 0.05 sec (50 ms)
    % TFRhann = ft_freqanalysis(cfg, dataCrowding1);
    %
    % cfg = [];
    % cfg.baseline     = [-0.5 -0.1];
    % cfg.baselinetype = 'absolute';
    % cfg.zlim         = [-2.5e-27 2.5e-27];
    % cfg.showlabels   = 'yes';
    % % cfg.layout       = 'CTF151_helmet.mat';
    % figure
    % set(gcf, 'Position', [200, 100, 1500, 1000]);  % Adjust the size (optional)
    % ft_multiplotTFR(cfg, TFRhann);
    % title('Frequency Analysis using Hanning; Cond1');
    % h = gcf;  % gcf gets the handle of the current figure
    % saveas(h, 'Frequ_Hanning_Cond1.png');
    %
    %
    %
    % cfg = [];
    % cfg.channel    = 'AG*';
    % cfg.method     = 'wavelet';
    % cfg.width      = 15;
    % cfg.output     = 'pow';
    % cfg.foi        = 12:2:30;
    % cfg.toi        = -1:0.05:0.5;
    % TFRwave = ft_freqanalysis(cfg, dataCrowding1);
    %
    % cfg = [];
    % cfg.baseline     = [-0.5 -0.1];
    % cfg.baselinetype = 'absolute';
    % cfg.zlim         = [-2e-25 2e-25];
    % cfg.showlabels   = 'yes';
    % % cfg.layout       = 'CTF151_helmet.mat';
    % cfg.colorbar     = 'yes';
    % figure
    % ft_multiplotTFR(cfg, TFRwave)
    % set(gcf, 'Position', [200, 100, 1500, 1000]);  % Adjust the size (optional)
    % title('Frequency Analysis using Wavelet; Cond1');
    % h = gcf;  % gcf gets the handle of the current figure
    % saveas(h, 'Frequ_Wavelet_Cond1.png');


end

