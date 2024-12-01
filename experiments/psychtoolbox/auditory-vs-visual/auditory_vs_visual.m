% Readapted for NYUAD MEG Lab by Hadi Zaatiti
% For Prof. David Melcher MEG demonstration 
% Original copyright:
% Copyright (c) 2019, Sijia Zhao.  All rights reserved.

% Experiment: Visual vs Auditory vs Motor activation
% Description: three types of conditions randomly permuted
    % Visual: White screen appear for two seconds
    % Auditory: 200hz frequency audio for 0.5 second
    % Motor: A button press is requested


%% 
clear;close all;clc
rng('shuffle');
dbstop if error;

%Screen('Preference', 'SkipSyncTests', 1);

%% Hardware parameters

el = 0; % 1 = Eyelink on; 0 = Eyelink off;

vpix_use = 1;    %Vpixx send triggers or not

DEBUG = false;
%% Experiment parameters

RESTING_STATE = false;  % If true then collect resting state data

expsbj = input(' NAME of PARTICIPANT? [eg. S10] = ','s');
thisblock = input(' BLOCK INDEX? = ');


% Number of trials per condition in the following order: 
% visual, auditory, motor
ntrial_c = [50, 50, 50];
ntrial = sum(ntrial_c);

ISI = 2:0.1:2.5; % [second] Inter-soundonset-interval. The distance between the onset of the current trial and the next sound
Fs = 44100; % sampling rate for sound play
stimDur = 0.5; % [second] sound duration. this must be pre-set and identical across all sounds

path_in = './SoundFiles/';

condlist = {'visual_stim','auditory_ht_200Hz','motor_button'};

black_rgb = [0 0 0];
white_rgb = [255 255 255];

%% Setup Vpixx

% Define trigger pixels for all usable MEG channels
% trig.ch224 = [4  0  0]; %224 meg channel
% trig.ch225 = [16  0  0];  %225 meg channel
% trig.ch226 = [64 0 0]; % 226 meg channel
% trig.ch227 = [0  1 0]; % 227 meg channel
% trig.ch228 = [0  4 0]; % 228 meg channel
% trig.ch229 = [0 16 0]; % 229 meg channel
% trig.ch230 = [0 64 0]; % 230 meg channel
% trig.ch231 = [0 0  1]; % 231 meg channel


trigRect = [0 0 1 1];

trigch224 = [4  0  0];  % 224 MEG CHANNEL: Resting state trigger
trigch225 = [16  0  0]; % 224 MEG CHANNEL:500 Hz audio trigger
trigch226 = [64 0 0];   % 225 MEG CHANNEL: White noise audio trigger
trigch227 = [0  1 0];   % 226 MEG CHANNEL: 200 Hz audio trigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 1 is visual stimulus = ch224
% 2 is auditory stimulus = ch225
% 3 is motor button = ch226


%%
ExpCond.condlist = condlist;

signal_sounds = {}; % read and store all three sounds
for i = 1:numel(condlist)
    filename = [path_in 'ht_200Hz.wav'];
    [signal_sounds{i},~] = audioread(filename);
end

% filename = [path_in 'ht_200Hz.wav'];
% signal_sound = audioread(filename);



ExpCond.numTrial = ntrial;
ExpCond.ISI = ISI;
ExpCond.stimDur = stimDur;

% Common eyetracking set up
ExpCond.distSc_Sbj = 65; % Distance from subject to monitor [cm] % CHANGE BASED ON YOUR SETUP!
ExpCond.ScWidth = 53.4; % Screen width [cm] % CHANGE BASED ON YOUR SETUP!
ExpCond.smpfreq = 1000; % Sampling rate of Eyelink [Hz] % CHANGE BASED ON YOUR SETUP!
ExpCond.linewidth = 7; % in pixels

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Set folders and filenames
ExpDataDrct = ['./Data/']; %this vector will be updated later (add date)
outfile = strcat(expsbj,'_');

% Eye-tracking data's filename (temporary)
switch el
    case 1
        Eyelinkuse = 'on';
    case 0
        Eyelinkuse = 'off';
end
ExpDrct =  './';
tmpname = '100'; %temporary name for eyetracking data

ExpDataDrct = [ExpDataDrct,'/'];
mkdir(ExpDataDrct);


str_exp = string(ExpDataDrct);
diary_string = strcat(ExpDataDrct,outfile,'_audiolog.asc');
diary(diary_string);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Compute the stimuli indexs for each block
shuffleidx = [];
for k = 1:numel(condlist)
    shuffleidx = [shuffleidx, k*ones(1,ntrial_c(k))];
end
triallist = shuffleidx(randperm(ntrial));

%% Add a constraint: make sure two deviants (2 or 3) are not next to each other
% % ## This part needs to be optimised.
% minDeviantDistance = 1;
% i_d = find(triallist~=1);
% flag_consc = find(diff(i_d)<=minDeviantDistance);
% while ~isempty(flag_consc)
%     triallist = shuffleidx(randperm(ntrial));
%     i_d = find(triallist~=1);
%     flag_consc = find(diff(i_d) <= minDeviantDistance);
%     disp('Reshuffle...');
% end
% % ## This part needs to be optimised.
% 
ExpCond.triallist = triallist;

%% Initialize PsychPortAudio & Create Buffer

%Uncomment to initial version
% InitializePsychSound(1);
% nsoundcard = 9; % Soundcard location % CHANGE BASED ON YOUR SETUP!
% padevice = PsychPortAudio('Open',nsoundcard,[],0,Fs); 
% PsychPortAudio('RunMode',padevice,1);
%End Uncomment to inital version


% Begin psychdemos
% Always init to 2 channels, for the sake of simplicity:
nrchannels = 2;

% Perform basic initialization of the sound driver:
InitializePsychSound;

suggestedLatencySecs = [];
if IsARM
    % ARM processor, probably the RaspberryPi SoC. This can not quite handle the
    % low latency settings of a Intel PC, so be more lenient:
    suggestedLatencySecs = 0.025;
    fprintf('Choosing a high suggestedLatencySecs setting of 25 msecs to account for lower performing ARM SoC.\n');
end

% Open the audio 'device' with default mode [] (== Only playback),
% and a required latencyclass of 1 == standard low-latency mode, as well as
% default playback frequency and 'nrchannels' sound output channels.
% This returns a handle 'pahandle' to the audio device:
device = [];
padevice = PsychPortAudio('Open', device, [], 1, [], nrchannels, [], suggestedLatencySecs);


% Get what freq'uency we are actually using for playback:
s = PsychPortAudio('GetStatus', padevice);



%End PsychDemos




%   Read wavname, extract stimuli information, and put audio to buffer
%   (prepare the sound)
BufferHandles = zeros(1,ntrial);
for k = 1:ntrial
    tmpwav = signal_sounds{triallist(k)};
    BufferHandles(k) = PsychPortAudio('CreateBuffer', padevice, repmat(tmpwav,1,2)');
end
clear tmpwav;

load([ExpDrct, 'Tone1000.mat']);
BufferHandles(ntrial+1) = PsychPortAudio('CreateBuffer', padevice, repmat(mywav,2,1));

% Archive the output latency for RT calculation
PsychPortAudio('FillBuffer',padevice,BufferHandles(ntrial+1));
PsychPortAudio('Start',padevice, 1, 0, 1);
diary off;

%% load audiolog (output latency)
filename = [ExpDataDrct,outfile,'_audiolog.asc'];
identifier = '%s %s %s %s %s %s %s %s %s %s %s %s';
fid = fopen(filename);
tmp = textscan(fid, identifier);
fclose(fid);
for k=1:length(tmp{11})
    if strcmp(tmp{11}{k},'latency')==1
        if strcmpi(tmp{10}{k},'output')==1
            Oindex = k;
            break
        end
    end
end


ExpCond.audlag = str2double(tmp{12}{Oindex}); % unit:[msec]
clear Oindex tmp

diary(diary_string);

%% Eyelink Setting
dummymode = 0;
KbName('UnifyKeyNames');
%Screen('Preference', 'VisualDebuglevel', 2);
PsychDebugWindowConfiguration(0, 1); % 1 for running exp; 0.5 for debugging
PsychDefaultSetup(2);
screens=Screen('Screens');

% screenNumber = 1;
screenNumber = max(screens);

[window,ExpCond.rect]=Screen('OpenWindow',screenNumber);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EyeLink Calibration %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(Eyelinkuse,'on')==1
    if ~dummymode, HideCursor; end
    commandwindow;
    fprintf('EyelinkToolbox Example\n\n\t');
    eyl=EyelinkInitDefaults(window);
    ListenChar(2);
    if ~EyelinkInit(dummymode, 1)
        fprintf('Eyelink Init aborted.\n');
        cleanup;  % cleanup function
        return;
    end
    [v,vs]=Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs );
    Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');
    %     Eyelink('Openfile',[EyelinkName,'.edf']);
    Eyelink('Openfile',[tmpname,'.edf']);
    EyelinkDoTrackerSetup(eyl);
    EyelinkDoDriftCorrection(eyl);
    Eyelink('StartRecording');
    WaitSecs(0.1);
    Eyelink('Message', 'SYNCTIME');
end
%%%%%%%%%%%%%%%%%%%%%% EyeLink Calibration End %%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% Set up Screens

white = WhiteIndex(window);
black = BlackIndex(window);
gray = (white+black)/2;
inc = white-gray;
%bgColor = [gray gray gray]*3/2;
bgColor = [black black black];
red = [black white white];
fixSize = [0 0 25 25];
fixColor = 10;
FBcolor = [180 180 180];

VA1deg.cm = 2*pi*ExpCond.distSc_Sbj/360;  % visual angle 1 deg [unit:cm]
VA05deg.cm = 2*pi*ExpCond.distSc_Sbj/360/2;  % visual angle 0.5 deg [unit:cm]
px_in_cm = ExpCond.ScWidth/ExpCond.rect(3); % one pixel on the specified screen [unit:cm]
VA1deg.px = floor(VA1deg.cm/px_in_cm); % visual angle 1 deg [unit:pixel]
VA05deg.px = floor(VA05deg.cm/px_in_cm); % visual angle 0.5 deg [unit:pixel]

% positions of the fixation point
centerpx = [ExpCond.rect(3)/2 ExpCond.rect(4)/2];       % position of the center H,V (in pixel)
fxpointH = [centerpx(1) centerpx(2) centerpx(1) centerpx(2)]+[-1 0 1 0]*floor(VA1deg.px/2);
fxpointV = [centerpx(1) centerpx(2) centerpx(1) centerpx(2)]+[0 -1 0 1]*floor(VA1deg.px/2);

textSize = 32;
text='Press SPACE KEY to start the experiment';
Screen('FillRect', window, bgColor);
Screen(window,'TextFont','Arial');
Screen(window,'TextSize',textSize);
x=(ExpCond.rect(3)-textSize*18)/2;
y=(ExpCond.rect(4)+textSize*0.75)/2;
Screen(window,'DrawText',text,x,y,[white white white]);
Screen('FillRect', window, black_rgb, trigRect);
Screen('Flip', window);

%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
done = 0;
while 1
    [ keyIsDown, ~, keyCode ] = KbCheck;
    if keyIsDown && done==0
        if keyCode(KbName('Space'))
            Screen('FillRect', window, bgColor);
            Screen('DrawLine', window, [black black black], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
            Screen('DrawLine', window, [black black black], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
            Screen('FillRect', window, black_rgb, trigRect);
            Screen('Flip', window);
            disp('START!');
            WaitSecs(1.5)
            done=1;
            break
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Experiment Part

Screen('FillRect', window, bgColor);
Screen('DrawLine', window, [white white white], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
Screen('DrawLine', window, [white white white], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
Screen('FillRect', window, black_rgb, trigRect);
Screen('Flip', window);

tmptime = GetSecs;

breakp = 0;



%% Resting state pupil diameter
if strcmp(Eyelinkuse,'on')==1
    
    feedback4fixation = 0;
    
    Eyelink('StartRecording'); % start recording (to the file)
    error = Eyelink('checkrecording'); % Check recording status, stop display if error
    
    % check for endsaccade events
    fixcenter = 0;
    while fixcenter==0
        if Eyelink('isconnected') == eyl.dummyconnected % in dummy mode use mousecoordinates
            [x,y] = GetMouse(window);
            evt.type = eyl.ENDSACC;
            evt.genx = x;
            evt.geny = y;
            evtype = eyl.ENDSACC;
        else % check for events
            evtype = Eyelink('getnextdatatype');
        end
        
        if evtype == eyl.ENDSACC % if the subject finished a saccade check if it fell on an object
            if Eyelink('isconnected') == eyl.connected % if we're really measuring eye-movements
                evt = Eyelink('getfloatdata', evtype); % get data
            end
            
            % check if saccade landed on fixation cross
            if 1 == IsInRect(evt.genx,evt.geny, [centerpx(1)-100,centerpx(2)-100,centerpx(1)+100,centerpx(2)+100])
                
                fixcenter = 1;
                if feedback4fixation
                    
                    Screen('FillRect', window, bgColor);
                    Screen('DrawLine', window, [black black black], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
                    Screen('DrawLine', window, [black black black], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
                    Screen('FillRect', window, black_rgb, trigRect);
                    Screen('Flip', window);
                end
                
            else % if not fixating, toggle red fixation !
                
                if feedback4fixation
                    Screen('FillRect', window, bgColor);
                    Screen('DrawLine', window, [black white white], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
                    Screen('DrawLine', window, [black white white], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
                    Screen('FillRect', window, black_rgb, trigRect);
                    Screen('Flip', window);
                end
                
            end
            WaitSecs(.1);
        end % saccade?
    end
    
    Screen('FillRect', window, bgColor);
    Screen('DrawLine', window, [black black black], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
    Screen('DrawLine', window, [black black black], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
    Screen('FillRect', window, black_rgb, trigRect);
    Screen('Flip', window);
    
    WaitSecs(2);
end % el




%% Wait for resting state

if RESTING_STATE

    disp(['Block:',thisblock,' Resting state starts (15s)']);
    disp('***');
    if strcmp(Eyelinkuse,'on') == 1
        Eyelink('Message', ['Resting: Resting_state_for_15s']);
    end
    WaitSecs(15);

end


% All works before




%% Check if you want to terminate the experiment
% [ keyIsDown, ~, keyCode ] = KbCheck;
% if keyCode(KbName('Escape'))
%     breakp = 1;
%     %break;
% end

%% Main experiment starts!


if vpix_use == 1
    %VIEW PIXX SETUP
    
    
    Datapixx('Open');
    Screen('FillRect', window, black_rgb, trigRect);
    Datapixx('EnablePixelMode');  % to use topleft pixel to code trigger information, see https://vpixx.com/vocal/pixelmode/
    Datapixx('RegWr');

end

%Debug only remove

% ntrial = 3;
% triallist = [1, 2, 3];


text_motor = 'Press the red button on the button box';

for k = 1:ntrial
       
    disp(['Block:',thisblock,' Trial:',num2str(k),' Condition: ', condlist{triallist(k)}]);
    disp('***');
    if strcmp(Eyelinkuse,'on')==1
        Eyelink('Message', ['Trial:',num2str(k),' ',condlist{triallist(k)}]);
    end
    
    disp('start')
    
        
        % Switch-case structure
        switch triallist(k)
            case 1  % Visual Stimulus
                disp('Visual start')

                Screen('FillRect', window, white_rgb);
                Screen('DrawLine', window, [black black black], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
                Screen('DrawLine', window, [black black black], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
                Screen('FillRect', window, trigch224, trigRect);
                Screen('Flip', window);
                Screen('FillRect', window, white_rgb);
                Screen('DrawLine', window, [black black black], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
                Screen('DrawLine', window, [black black black], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
                Screen('FillRect', window, black_rgb, trigRect);
                Screen('Flip', window);
                
                WaitSecs(0.5);

                Screen('FillRect', window, black_rgb);
                Screen('DrawLine', window, [white white white], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
                Screen('DrawLine', window, [white white white], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
                Screen('FillRect', window, black_rgb, trigRect);
                Screen('Flip', window);
                
                if DEBUG

                    % Debug only
                    text='Visual stim done';
                    Screen('FillRect', window, bgColor);
                    Screen(window,'TextFont','Arial');
                    Screen(window,'TextSize',textSize);
                    x=(ExpCond.rect(3)-textSize*18)/2;
                    y=(ExpCond.rect(4)+textSize*0.75)/2;
                    Screen(window,'DrawText',text,x,y,[white white white]);
                    Screen('FillRect', window, black_rgb, trigRect);
                    Screen('Flip', window);
    
                    WaitSecs(0.5);

                end
                
            case 2  % Auditory Stimulus
                    %% Play sound
                disp('Auditory start')
                
                Screen('FillRect', window, black_rgb);
                Screen('DrawLine', window, [white white white], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
                Screen('DrawLine', window, [white white white], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
                Screen('FillRect', window, trigch225, trigRect);
                Screen('Flip', window);
                Screen('FillRect', window, black_rgb);
                Screen('DrawLine', window, [white white white], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
                Screen('DrawLine', window, [white white white], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
                Screen('FillRect', window, black_rgb, trigRect);
                Screen('Flip', window);
                PsychPortAudio('FillBuffer',padevice,BufferHandles(k));
                PsychPortAudio('Start', padevice, 1, 0, 1); %Start audio playback, return onset timestamp
                
                
                
                if DEBUG
                    % Debug only
                    text='Auditory Done';
                    Screen('FillRect', window, bgColor);
                    Screen(window,'TextFont','Arial');
                    Screen(window,'TextSize',textSize);
                    x=(ExpCond.rect(3)-textSize*18)/2;
                    y=(ExpCond.rect(4)+textSize*0.75)/2;
                    Screen(window,'DrawText',text,x,y,[white white white]);
                    Screen('FillRect', window, black_rgb, trigRect);
                    Screen('Flip', window);

                    WaitSecs(0.5);
                end

            case 3  % Motor Response Box stimulus

                disp('Motor start')
                
                Screen('FillRect', window, bgColor);
                Screen(window,'TextFont','Arial');
                Screen(window,'TextSize',textSize);
                x=(ExpCond.rect(3)-textSize*18)/2;
                y=(ExpCond.rect(4)+textSize*0.75)/2+30;
                Screen(window,'DrawText',text_motor,x,y,[white white white]);
                Screen('DrawLine', window, [white white white], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
                Screen('DrawLine', window, [white white white], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
                Screen('FillRect', window, black_rgb, trigRect);
                Screen('Flip', window);
                getButton();
                Screen('FillRect', window, black_rgb);
                Screen('DrawLine', window, [white white white], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
                Screen('DrawLine', window, [white white white], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
                Screen('FillRect', window, trigch226, trigRect);
                Screen('Flip', window);
                Screen('FillRect', window, black_rgb);
                Screen('DrawLine', window, [white white white], fxpointH(1), fxpointH(2), fxpointH(3), fxpointH(4), 4);
                Screen('DrawLine', window, [white white white], fxpointV(1), fxpointV(2), fxpointV(3), fxpointV(4), 4);
                Screen('FillRect', window, black_rgb, trigRect);
                Screen('Flip', window);


                if DEBUG
                    % Debug only
                    text='Motor Done';
                    Screen('FillRect', window, bgColor);
                    Screen(window,'TextFont','Arial');
                    Screen(window,'TextSize',textSize);
                    x=(ExpCond.rect(3)-textSize*18)/2;
                    y=(ExpCond.rect(4)+textSize*0.75)/2;
                    Screen(window,'DrawText',text,x,y,[white white white]);
                    Screen('FillRect', window, black_rgb, trigRect);
                    Screen('Flip', window);

                    WaitSecs(0.5);
                end

            otherwise
                disp('Invalid condition');
        end


        % For debugging only
        % WaitSecs(5);
        % Screen('CloseAll');
    

    %% Wait for ISI
    WaitSecs(ISI(randperm(length(ISI),1))); %wait for ISI
    
    %% Check if you want to terminate the experiment
    [ keyIsDown, ~, keyCode ] = KbCheck;
    if keyCode(KbName('Escape'))
        breakp = 1;
        break
    end
end


%%

totaltime = GetSecs - tmptime;

%ListenChar(0);
for k=1:ntrial
    PsychPortAudio('DeleteBuffer',BufferHandles(k));
end
PsychPortAudio('Close');

if breakp==0
    text='FINISHED!';
elseif breakp==1
    text='ABORTED!';
end
Screen('FillRect', window, bgColor);
Screen(window,'TextFont','Arial');
Screen(window,'TextSize',textSize);
x=(ExpCond.rect(3)-textSize*8)/2;
y=(ExpCond.rect(4)+textSize*0.75)/2;
Screen(window,'DrawText',text,x,y,[black black black]);
Screen('FillRect', window, black_rgb, trigRect);
Screen('Flip', window);
WaitSecs(1.5);




%%
if strcmp(Eyelinkuse,'on')==1
    
    EyelinkName=[ExpDataDrct outfile];
    
    Eyelink('Stoprecording');
    Eyelink('ReceiveFile',tmpname); % copy the file from eyetracker PC to Stim PC
    Eyelink('CloseFile');
    Eyelink('Shutdown');
    if breakp==0
        command = ['edf2asc ',tmpname,'.edf -ns'];
        status = dos(command);
        command = ['rename ',tmpname,'.asc ',tmpname,'_event.asc '];
        status = dos(command);
        command = ['edf2asc ',tmpname,'.edf -ne'];
        status = dos(command);
        command = ['rename ',tmpname,'.asc ',tmpname,'_sample.asc '];
        status = dos(command);
        movefile([tmpname '.edf'],[EyelinkName '.edf']);
        movefile([tmpname '_sample.asc'],[EyelinkName '_sample.asc']);
        movefile([tmpname '_event.asc'],[EyelinkName '_event.asc']);
    end
end




% Ensure all parts are strings
ExpDataDrct = string(ExpDataDrct);

% Create the filename by concatenating the parts
filename = strcat(ExpDataDrct, 'result_', outfile, '.mat');

%filename = [ExpDataDrct,'result_',outfile,'.mat']; %changed by Sijia
if breakp==0 %&& ifpractice==0 %&& Sblock~=0
    
    save(filename,'ExpCond');
    disp('----- EXPERIMENT FINISHIED -----')
    disp(['- TOTAL TIME: ',num2str(totaltime)])
elseif breakp==1
    disp('----- EXPERIMENT ABORTED -----')
    disp(['- TOTAL TIME: ',num2str(totaltime)])
end
diary off;


textend='Stop the MEG recording and press SPACE KEY to END the experiment';
Screen('FillRect', window, bgColor);
Screen(window,'TextFont','Arial');
Screen(window,'TextSize',textSize);
x=(ExpCond.rect(3)-textSize*18)/2;
y=(ExpCond.rect(4)+textSize*0.75)/2;
Screen(window,'DrawText',textend,x,y,[white white white]);
Screen('FillRect', window, black_rgb, trigRect);
Screen('Flip', window);


while 1
    [ keyIsDown, ~, keyCode ] = KbCheck;
    WaitSecs(0.2);
    if keyIsDown
        if keyCode(KbName('Space'))
            break
        end
    end
end


Screen('CloseAll');

if vpix_use == 1
    %VIEW PIXX SETUP
    Datapixx('DisablePixelMode');  % to use topleft pixel to code trigger information, see https://vpixx.com/vocal/pixelmode/
    Datapixx('SetDoutValues', 0);
    Datapixx('Close');
    disp('Datapixx Vpixx Closed')
end
