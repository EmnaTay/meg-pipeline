% This script averages the ERPs over all subjects for the three conditions
% for a specific channel

%%

% Define the paths to the results folder
resultsFolder = 'Averaging Results';

% Get a list of all subject folders in the results folder
subjectFolders = dir(fullfile(resultsFolder, 'Sub_*'));

% Initialize structures to accumulate the data
accumCWDG1 = [];
accumCWDG2 = [];
accumCWDG3 = [];

% Initialize a counter to keep track of the number of subjects
numSubjects = 0;

% Loop over each subject folder
for k = 1:length(subjectFolders)
    % Get the current subject folder name
    subjectFolder = fullfile(resultsFolder, subjectFolders(k).name);
    
    % Check if it is a directory
    if ~subjectFolders(k).isdir
        continue;
    end
    
    % Load the data for each condition using FieldTrip's ft_timelockgrandaverage
    avgCWDG1File = fullfile(subjectFolder, sprintf('%s_avgCWDG1.mat', subjectFolders(k).name));
    avgCWDG2File = fullfile(subjectFolder, sprintf('%s_avgCWDG2.mat', subjectFolders(k).name));
    avgCWDG3File = fullfile(subjectFolder, sprintf('%s_avgCWDG3.mat', subjectFolders(k).name));
    
    if exist(avgCWDG1File, 'file') && exist(avgCWDG2File, 'file') && exist(avgCWDG3File, 'file')
        load(avgCWDG1File, 'avgCWDG1');
        load(avgCWDG2File, 'avgCWDG2');
        load(avgCWDG3File, 'avgCWDG3');
        
        % Accumulate the data using FieldTrip's ft_timelockgrandaverage
        if isempty(accumCWDG1)
            cfg = [];
            accumCWDG1 = ft_timelockgrandaverage(cfg, avgCWDG1);
            accumCWDG2 = ft_timelockgrandaverage(cfg, avgCWDG2);
            accumCWDG3 = ft_timelockgrandaverage(cfg, avgCWDG3);
        else
            cfg = [];
            accumCWDG1 = ft_timelockgrandaverage(cfg, accumCWDG1, avgCWDG1);
            accumCWDG2 = ft_timelockgrandaverage(cfg, accumCWDG2, avgCWDG2);
            accumCWDG3 = ft_timelockgrandaverage(cfg, accumCWDG3, avgCWDG3);
        end
        
        % Increment the number of subjects
        numSubjects = numSubjects + 1;
    else
        fprintf('Missing data for subject: %s\n', subjectFolders(k).name);
    end
end

% Save the averaged data
save(fullfile(resultsFolder, 'avgCWDG1_overall.mat'), 'accumCWDG1');
save(fullfile(resultsFolder, 'avgCWDG2_overall.mat'), 'accumCWDG2');
save(fullfile(resultsFolder, 'avgCWDG3_overall.mat'), 'accumCWDG3');

% Plot the averaged ERPs for a specific channel
cfg = [];
cfg.xlim = [-0.2 1.0];
cfg.ylim = [-1e-13 3e-13];
cfg.channel = 'AG001';
ft_singleplotER(cfg, accumCWDG1, accumCWDG2, accumCWDG3);
title('Averaged ERP Activity Across Subjects for Channel AG001');

saveas(gcf, fullfile(resultsFolder, sprintf('AVG_ERP.png')));
