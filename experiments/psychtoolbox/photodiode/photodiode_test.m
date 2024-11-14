%% Face Working Memory MEG (FWWM) Study
% 05/11/24: written  by Gayathri Satheesh (gayathri.s.satheesh@gmail.com)


% The goal of this script is to do a sanity check on the time that it takes for a frame sent from the stimulus computer
% to be seen by the participant in the KIT machine
% Let us call this, the "stimulus to propixx lag" and denote it x (in ms)
% Another lag is the time for the stimulus comput5er to send a trigger to the KIT machine, denote this lag y (in ms)
% The photodiode can give us the ground truth on the KIT machine of when the visual stimulus indeed appeared, and help correct the y lag
% However the photodiode cannot tell us anything about the x lag (but we do not care about this one, because the brain reaction happens only after the person actually saw the stimulus)


% The idea is to use a photodiode that will capture changes in colors on a square turning from black to white
% the square is initially black after 500 ms it will turn white

% if we have a trigger indicating the white square sent from the stimulus computer to the KIT, then the photodiode can tell us the lag
% At the photodiode channel 233
% At the same time, when the square turns white, we will trigger channel 224 with a pulse
% We will check on the KIT data when the 224 trigger arrives and when the photodiode captures the white and measure that across multiple trials
% The monitor is at 120 Hz, we should see a frame every 8.333 ms, when we are showing a white square the photodiode is showing spikes
%   We can check that the spikes are happening every 8.333 ms, this confirms that the photodiode is sensitivie to the refresh equilibrate(
%

sca; clear ALL; %clean slate
%% --------------------------------------------------------------------- %%
%   experiment set-Up
%% --------------------------------------------------------------------- %%
ds.debug = 1;
% 1 for coding in laptop (skip synchronization tests)
% 0 for experiment in MEG (keep synchronization tests)

ds.usedatapixx = 0;
% 1 for datapixx open for trigger and response
% 0 for datapixx NOT open (no trigger, no vpixx response)

ds.little_window = 0;
% display little window in the same screen: 1 true, 0 false

trg.trigger_test = 0;
% if 0, trigger is 1 pixel (for exeriment),
% if 1 trigger is bigger (to be able to see it during debugging)

ds.Vpixx_response = 0;
% if 0, laptop keyboard responses (debugging)
% if 1, Vpixx response buttons
%% --------------------------------------------------------------------- %%
%   environment set-up
%% --------------------------------------------------------------------- %%
path_local = '/Users/wkc267/Documents/GitHub/FWMM_beh_meg';
path_local2 = '/Users/hannah/Documents/GitHub/FWMM_beh_meg';
path_meg = 'C:\Users\vpixx\Desktop\sreenivasan_lab\FWMM_beh_meg_gs';

%% --------------------------------------------------------------------- %%
%   disable pixel-mode
%% --------------------------------------------------------------------- %%

if ds.usedatapixx ==1
    Datapixx('Open')
    Datapixx('SetPropixxDlpSequenceProgram', 0)
    Datapixx('DisablePixelMode')
    Datapixx('RegWr')
end

%qq set project directory
if isfolder(path_local)
    PROJ_DIR = path_local;
elseif isfolder(path_local2)
    PROJ_DIR = path_local2;
elseif isfolder(path_meg)
    PROJ_DIR = path_meg;
else
    PROJ_DIR = pwd;
end

cd(PROJ_DIR);
addpath(genpath("imageTextures"),"taskmaps",genpath("scripts")) % add helper functions to path
expID = 'FWMM';
%get today's date
todayDate = datetime('now','Format','yyMMdd');
dateStr = string(todayDate);

%% --------------------------------------------------------------------- %%
%   display set-up / VPixx
%% --------------------------------------------------------------------- %%


%% -- set size and location of trigger pixel -- %%
baseRect_trigger = [0 0 1 1];
trg.centeredRect_trigger = CenterRectOnPointd(baseRect_trigger, 0.5, 0.5);

% initialize PTB and screen
ds = SetupDisplay(ds);
HideCursor(); %hide cursor

%initialize photodiode patch
baseRect_photoDiode = [0 0 250 250];
% Center the rectangle in the bottom-left corner
bottomLeftX = 25;  % X position, a bit in from the left edge
bottomLeftY = ds.height - 25;  % Y position, adjusted from bottom of screen
trg.centeredRect_photoDiode = CenterRectOnPointd(baseRect_photoDiode, bottomLeftX, bottomLeftY);


% initiate kbcheck
kb = SetupKeyboard();

% baseline quit flag
exit_task = 0;
timeout = 0;

%% --------------------------------------------------------------------- %%
%   trigger start of experiment
%% --------------------------------------------------------------------- %%
key5 = [KbName('5%') KbName('5')];


% press the 5 key to trigger start of the experiment
key5down=0;
%draw grey background to the screen


%
% # TODO: The rule is:
%     # Everytime I use Background grey then Screen(ds.w, 'flip')
%         # I put just before this line, the top-left pixel to black to make sure that no incorrect triggers are there
%         # Now, if i want to trigger something:
%             # I prepare the graphics on the screen (ex: grey background) then I set the top-left pixel to the color of the trigger i want and only then, i flip
%                 # RIght after flipping, wait for a small amount of time that wouldn't ruin your trials, and then reput back whatever graphics you want, then set the top-left pixel to black, then flip
%% --------------------------------------------------------------------- %%
%   enable pixel mode
%% --------------------------------------------------------------------- %%

Screen('FillRect', ds.w, [0 0 0], trg.centeredRect_trigger);
Screen(ds.w,'flip');

if ds.usedatapixx == 1
  % Tell PTB we want to display on a DataPixx device
    Datapixx('Open');
    Datapixx('EnablePixelMode'); % trigger pixel mode
    Datapixx('RegWrRd'); % Synchronize DATAPixx registers to local register cache
end

trg.start=[0 80 0];
trg.noTrg= [0 0 0];
% specify fixation dot size
stim.fixSize_deg = 2; %2 deg? 1deg?
stim.fixSize_pix = ceil(Deg2Pix(stim.fixSize_deg,ds.viewDist,ds.res));

%% --------------------------------------------------------------------- %%
%   Start screen
%% --------------------------------------------------------------------- %%
%trigger task start
% Screen('FillRect', ds.w, trg.start, trg.centeredRect_trigger);
% ds.vbl = Screen(ds.w,'flip');
%draw grey background to the screen




while ~key5down
    Screen('FillRect', ds.w, ds.grey, ds.centeredRect);
    DrawFormattedText2('Experiment will start shortly...','win',ds.w, 'sx','center','sy','center','baseColor', ds.black,'xlayout','center','xalign','center','yalign','center');
    Screen('FillRect', ds.w, ds.black,trg.centeredRect_photoDiode);
    Screen('FillRect', ds.w, [0 0 0], trg.centeredRect_trigger);
    Screen(ds.w,'flip');
    [keyisdown, secs, keycode] = KbCheck(-1);
    key5down = keycode(key5);
end

    Screen('FillRect', ds.w, ds.grey, ds.centeredRect);
    Screen('FillRect', ds.w, ds.white,trg.centeredRect_photoDiode);
    Screen('FillRect', ds.w, [0 16 0], trg.centeredRect_trigger);
    Screen(ds.w,'flip');
    Screen('FillRect', ds.w, ds.grey, ds.centeredRect);
    Screen('FillRect', ds.w, ds.black,trg.centeredRect_photoDiode);
    Screen('FillRect', ds.w, [0 0 0], trg.centeredRect_trigger);
    Screen(ds.w,'flip');

%% --------------------------------------------------------------------- %%
%   present stimulus
%% --------------------------------------------------------------------- %%

WaitSecs(2);
numTrials=50;
ds.vbl2 = GetSecs(); % Unit is seconds
ds.vbl = GetSecs();

for trial = 1:numTrials

        while ds.vbl2<ds.vbl+1
            tic
            Screen('DrawDots',ds.w,[ds.xCenter, ds.yCenter], stim.fixSize_pix, ds.black,[],1);
            % Channel 224 triggering
            Screen('FillRect', ds.w, [4 0 0], trg.centeredRect_trigger);
            % Square photodiode to white
            Screen('FillRect', ds.w, ds.white,trg.centeredRect_photoDiode);
            ds.vbl2 = Screen(ds.w,'flip');
        end

        while ds.vbl<ds.vbl2+1
            % trigger off
            Screen('DrawDots',ds.w,[ds.xCenter, ds.yCenter], stim.fixSize_pix, ds.black,[],1);
            Screen('FillRect', ds.w,[0 0 0], trg.centeredRect_trigger);
            % Square photodiode to black
            Screen('FillRect', ds.w, ds.black,trg.centeredRect_photoDiode);
            ds.vbl = Screen(ds.w,'flip');
        end

    %write to file

    % end of last trial screen
end


DrawFormattedText2('End of the experiment!','win',ds.w, 'sx','center','sy',ds.line2,'baseColor', ds.black,'xlayout','center','xalign','center','yalign','center');

Screen('FillRect', ds.w, trg.noTrg, trg.centeredRect_trigger);
Screen('FillRect', ds.w, ds.black,trg.centeredRect_photoDiode);
Screen(ds.w,'flip');


% press the 5 key to trigger start of the experiment
key5down=0;
ListenChar(0);% enable transmission of keypresses to Matlab
while ~key5down
    [keyisdown, secs, keycode] = KbCheck(-1);
    key5down = keycode(key5);
end

% VPixx clean up
if ds.usedatapixx
    Datapixx('DisablePixelMode');
    Datapixx('RegWr');
    Datapixx('Close');
end

ShowCursor();
sca

