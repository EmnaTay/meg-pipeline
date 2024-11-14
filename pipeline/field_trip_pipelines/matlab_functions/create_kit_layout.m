function layout = create_kit_layout(kit_filename)
%% This function creates Creating a custom channel layout for KIT system at NYUAD
%% Written: Osama Abdullah
grad = ft_read_sens(kit_filename); % this can be inspected with ft_plot_sens(grad)

% prepare the custom channel layout
cfg                         = [];
cfg.grad                    = grad;
layout                      = ft_prepare_layout(cfg);
sel                         = 1:(length(layout.label)-2); % the last two are COMNT and SCALE

% scale & stretch the position of the sensors
layout.pos(sel,:)           = layout.pos(sel,:) * 1.05;
layout.pos(sel,2)           = layout.pos(sel,2) * 1.08 + 0.02;

% load the CTF151 helmet and mask
cfg                         = [];
cfg.layout                  = 'CTF151_helmet';
ctf151                      = ft_prepare_layout(cfg);

% use the CTF151 outlint and mask instead of the circle
layout.outline              = ctf151.outline;
layout.mask                 = ctf151.mask;

