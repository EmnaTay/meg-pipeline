% Paths to the directories
folder1 = 'C:\Users\hz3752\AppData\Roaming\MathWorks\MATLAB Add-Ons\Collections\Psychtoolbox-3\Psychtoolbox\PsychBasic\MatlabWindowsFilesR2007a';
folder2 = 'C:\Users\hz3752\AppData\Roaming\MathWorks\MATLAB Add-Ons\Collections\Psychtoolbox-3\Psychtoolbox\PsychHardware';

% Remove both folders if they exist to avoid duplicates
rmpath(folder1);
rmpath(folder2);

% Add folder1 first, then folder2
addpath(folder1, '-begin');
addpath(folder2, '-end');

% Save the path to make the changes persistent
savepath;