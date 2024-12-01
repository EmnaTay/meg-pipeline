% Simple plot script from KIT-MEG dataset file

MEG_DATA_FOLDER = getenv('MEG_DATA');


%%

DATASET_PATH = [MEG_DATA_FOLDER,'visual_crowding_preview\sub-001-vcp\meg-kit\sub-001-vcp-analysis_NR.con'];

%Load the data into fieldtrip

cfg =[];

cfg.dataset = DATASET_PATH;

cfg.coilaccuracy = 0;

data_all = ft_preprocessing(cfg);

% Plot the data

cfg = [];

cfg.viewmode = 'vertical';
cfg.blocksize = 300; %in seconds;
ft_databrowser(cfg, data_all);