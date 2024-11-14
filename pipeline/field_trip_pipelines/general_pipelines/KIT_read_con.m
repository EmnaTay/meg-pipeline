
% load in the data
cfg              = [];
cfg.dataset      = 'emptyroom_10.con';
cfg.coilaccuracy = 0;
data_all         = ft_preprocessing(cfg);


% Read the header
hdr = ft_read_header(cfg.dataset);

% Display the header information
disp(hdr);