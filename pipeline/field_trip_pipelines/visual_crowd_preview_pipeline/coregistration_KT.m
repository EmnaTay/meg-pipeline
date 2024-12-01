%% Coregister 5 HPI coils from mrk file with 8 points from polhemus laser scan

%% configure paths

MEG_DATA_FOLDER = getenv('MEG_DATA');

% Set path to KIT .con file of sub-03
DATASET_PATH = [MEG_DATA_FOLDER,'visual_crowding_preview'];

% This needs fixing to save properly
SAVE_PATH = [MEG_DATA_FOLDER, 'visual_crowding_preview'];

%% MEGFILES, POLHEMUS_FILES, MRK_FILES

% Get a list of all MEG data files
MEGFILES = dir(fullfile(DATASET_PATH, 'sub-*-vcp','meg-kit', 'sub-*-vcp-analysis_NR.con'));

% Get a list of all the Polhemus files
POLHEMUS_FILES = dir(fullfile(DATASET_PATH, 'sub-*-vcp','digitizer', 'sub-*-scan*.txt'));

% Get a list of all the .mrk files
MRK_FILES = dir(fullfile(DATASET_PATH, 'sub-*-vcp','meg-kit', '*.mrk'));

for k = 1

    % Get the current MEG data file name   
    confile = fullfile(MEGFILES(k).folder, MEGFILES(k).name);

    laser_stylus = fullfile(POLHEMUS_FILES(k).folder, POLHEMUS_FILES(k).name);
    laser_surf = fullfile(POLHEMUS_FILES(k+1).folder, POLHEMUS_FILES(k+1).name);

    mrkfile1 = fullfile(MRK_FILES(k).folder, MRK_FILES(k).name);
    mrkfile2 = fullfile(MRK_FILES(k+1).folder, MRK_FILES(k+1).name);

end

% Display the paths to ensure they are correct
disp(['Confile Path: ', confile]);
disp(['Laser Surface Path: ', laser_surf]);
disp(['Laser Points Path: ', laser_stylus]);


%% load lasershape

addpath C:\Users\user\Documents\GitHub\meg-pipeline\pipeline\field_trip_pipelines\matlab_functions
lasershape   = read_head_shape_laser(laser_surf, laser_stylus);
lasershape   = ft_convert_units(lasershape, 'm'); % convert everything to SI units

% Keep only x, y, z (not dx, dy, dz)
lasershape.fid.pos = lasershape.fid.pos(:,1:3);


%% load mrk

mrk1 = ft_read_headshape(mrkfile1);
mrk1 = ft_convert_units(mrk1, lasershape.unit);
mrk2 = ft_read_headshape(mrkfile2);
mrk2 = ft_convert_units(mrk2, lasershape.unit);

% Define the average marker positions, mrk1 correspond to HPI coils at the
% beginning and end of the experiment
mrka = mrk1;
mrka.fid.pos = (mrk1.fid.pos+ mrk2.fid.pos)/2;

%% plot mrk and lasershape points

% Plotting a 3D scatter plot of the head scan points and the coils before
% transforming 
scatter3(lasershape.fid.pos(:,1), lasershape.fid.pos(:,2), lasershape.fid.pos(:,3), 'filled'); % plot of the head scan points in 3D
hold on
scatter3(mrka.fid.pos(:, 1), mrka.fid.pos(:, 2), mrka.fid.pos(:, 3), 'filled') % plot of the coils 

% Adding labels to the coil points
for i = 1:length(mrka.fid.label)
    text(mrka.fid.pos(i,1), mrka.fid.pos(i, 2), mrka.fid.pos(i, 3), mrka.fid.label{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'right');
end

% Adding labels to the headshape points
for i = 1:length(lasershape.fid.label)
    text(lasershape.fid.pos(i,1), lasershape.fid.pos(i,2), lasershape.fid.pos(i,3), lasershape.fid.label{i}, 'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'left');
end

%% load sensors

% read sensors from confile
grad   = ft_read_sens(confile, 'senstype', 'meg');
grad_m = ft_convert_units(grad, lasershape.unit);

grad_m.fid.pos(1,:) = mrka.fid.pos(1,:);  % CF
grad_m.fid.pos(2,:) = mrka.fid.pos(2,:);  % lpa
grad_m.fid.pos(3,:) = mrka.fid.pos(3,:);  % rpa
grad_m.fid.label    = {'CF', 'LPA', 'RPA'};

%% Before the coregistration

% check if HPI coils and laserscan are coregistered
figure;
ft_plot_sens(grad_m)
hold on
ft_plot_headshape(lasershape)

%% Coregister mrk with lasershape

% "black coil" is Number 1 (nas) in the .mrk which correspond to 6 (CF) in the stylus points
% "red coil" is number 2 (lpa) in the .mrk which correspond to 4 (LPA) in the stylus
% "yellow coil" is number 3 (rpa) in the .mrk which correspond to 5 (RPA) in the stylus
% "white coil" is number 4 (marker 4) in the .mrk which correspond to 7 (LF) in the stylus
% "blue coil" is number 5 (marker 5) in the .mrk which correspond to 8 (RF) in the stylus

%% way1: bring both mrk and lasershape to 'ctf' coordsys

mrk2ctf   = ft_headcoordinates(mrka.fid.pos(1,:), mrka.fid.pos(2,:), mrka.fid.pos(3,:), 'ctf'); 
laser2ctf = ft_headcoordinates(lasershape.fid.pos(6,:), lasershape.fid.pos(4,:), lasershape.fid.pos(5,:),'ctf'); % 6: NAS, 4: LPA 5:RPA

grad_mrk2ctf         = ft_transform_geometry(mrk2ctf, grad_m);
lasershape_laser2ctf = ft_transform_geometry(laser2ctf, lasershape);

% check if HPI coils and laserscan are coregistered
figure;
ft_plot_sens(grad_mrk2ctf)
hold on
ft_plot_headshape(lasershape_laser2ctf)
title('way1')

% save
for k = 1
    % Define the subject ID based on k
    subject_id = sprintf('sub-%03d-vcp', k);
    
    % Define the folder path
    derivatives_folder = fullfile(SAVE_PATH, subject_id, 'derivatives');
   
    % Save the data files in the defined folder
    save(fullfile(derivatives_folder, 'grad_mrk2ctf.mat'), 'grad_mrk2ctf');
    save(fullfile(derivatives_folder, 'lasershape_laser2ctf.mat'), 'lasershape_laser2ctf');
end

load(fullfile(derivatives_folder, 'grad_mrk2ctf.mat'), 'grad_mrk2ctf');
load(fullfile(derivatives_folder, 'lasershape_laser2ctf.mat'), 'lasershape_laser2ctf');

%% way2: bring mrk to the laserscan coordsys

mrk2ctf   = ft_headcoordinates(mrka.fid.pos(1,:), mrka.fid.pos(2,:), mrka.fid.pos(3,:), 'ctf'); 
laser2ctf = ft_headcoordinates(lasershape.fid.pos(6,:), lasershape.fid.pos(4,:), lasershape.fid.pos(5,:),'ctf'); % 6: NAS, 4: LPA 5"RPA

laser2mrk = mrk2ctf\laser2ctf;

lasershape_laser2mrk = ft_transform_geometry(laser2mrk, lasershape);

% check if HPI coils and laserscan are coregistered
figure;
ft_plot_sens(grad_m, 'fidcolor' ,'r')
hold on
ft_plot_headshape(lasershape_laser2mrk, 'vertexcolor', 'skin', 'vertexsize', 4)
title('way2')


%% way3: ft_interactiverealign - do it manually

grad_m.fid.pos(1,:) = mrka.fid.pos(1,:);   
grad_m.fid.pos(2,:) = mrka.fid.pos(2,:); 
grad_m.fid.pos(3,:) = mrka.fid.pos(3,:); 
grad_m.fid.label    = {'CF', 'LPA', 'RPA'};


cfg                    = [];
cfg.individual.grad    = grad_m;
cfg.template.headshape = lasershape;
[cfg] = ft_interactiverealign(cfg);

