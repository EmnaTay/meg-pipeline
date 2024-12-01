%


confile = 'MEG data/Subj_001_02.con';
%Load the data into fieldtrip

cfg =[];

cfg.dataset = confile;

cfg.coilaccuracy = 0;

data_all = ft_preprocessing(cfg);

% Plot the data

cfg = [];

cfg.viewmode = 'vertical';
cfg.blocksize = 300; %in seconds;
ft_databrowser(cfg, data_all);