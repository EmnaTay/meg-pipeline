% Sample script for reading OPM .fif file
% Author: Hadi Zaatiti <hadi.zaatiti@nyu.edu>




% Reading .fif file


% Set the environment variable to NYU BOX


% Read the environment variable to NYU BOX
MEG_DATA_FOLDER = getenv('MEG_DATA');

% Set path to OPM .fif file of sub-03
DATASET_PATH = [MEG_DATA_FOLDER, '\Phantom-Calibration-Data\sub-markercoil\20241015_111855_sub-MarkerCoil_file-Preliminarymeasurement_raw.fif'];



%% Data initialisation

% Tutorial reference: https://www.fieldtriptoolbox.org/tutorial/eventrelatedaveraging/

cfg                         = [];
cfg.dataset = DATASET_PATH;

data_all = ft_preprocessing(cfg);

% Read the header
hdr = ft_read_header(cfg.dataset);

% Display the header information
disp(hdr);




%% Plot sensors

sensors = ft_convert_units(data_all.grad, 'mm');

figure
ft_plot_sens(sensors)
hold on

sensors2 = ft_convert_units(hdr.grad, 'mm');

figure
ft_plot_sens(sensors2)
hold on


