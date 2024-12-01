
Atlas = ft_read_atlas('C:\Users\tasni\Desktop\Masterarbeit\atlas\aal\ROI_MNI_V4.nii');

% Load the MNI template MRI
mri = ft_read_mri('C:\Users\tasni\Desktop\Masterarbeit\anatomy\Subject01.mri');


cfg = [];
cfg.method = 'headshape';
cfg.headshape = headshape;  % This is the aligned headshape struct
cfg.coordsys = 'ctf';       % Ensure consistency with your MEG data's coordinate system

% Align the MRI to the headshape
mri_aligned = ft_volumerealign(cfg, mri);

cfg            = [];
cfg.resolution = 1;
cfg.dim        = [256 256 256];
mri            = ft_volumereslice(cfg, mri_aligned);

%% segmentation MRI
cfg           = [];
cfg.output    = {'brain', 'skull', 'scalp'};
segmentedmri  = ft_volumesegment(cfg, mri_aligned);

cfg = [];
cfg.method='singleshell';
mriskullmodel = ft_prepare_headmodel(cfg, segmentedmri);

cfg = [];
cfg.tissue      = {'brain', 'skull', 'scalp'};
cfg.numvertices = [3000 2000 1000];
mesh = ft_prepare_mesh(cfg, segmentedmri);

cfg = [];
cfg.grad = grad;  % Use the transformed grad structure
cfg.headshape = mesh;  % Your headshape mesh
cfg.headmodel = mriskullmodel;  % Your head model
cfg.mri = mri_aligned;  % Aligned MRI data
cfg.mesh = headshape;  % Headshape mesh structure
cfg.axes = 'yes';  % Display axes

ft_geometryplot(cfg);









