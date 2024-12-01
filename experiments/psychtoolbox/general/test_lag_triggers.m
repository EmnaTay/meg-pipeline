%% This script should allow testing the lag of sending a trigger from stimulus computer to the KIT system

clearvars; clc
%Screen('Preference', 'SkipSyncTests', 1);
%AssertOpenGL;  


% Configuration parameters
 
vpix_use = 1; % 0 if vpixx is not conected
trigger_test = 1; 
% if 0, trigger is 1 pixel, 
% if 1 trigger is bigger (to be able to see it)

% SCREEN SETUP
PsychDebugWindowConfiguration(0, 1); % 1 for running exp; 0.5 for debugging
PsychDefaultSetup(2);
s = Screen('Screens');
s = max(Screen('Screens'));
%s = max(s);


%Colors definition in RGB
black = [0 0 0];
white = [255 255 255];

% Get pointer to screen window and a point
[w, rect] = Screen('Openwindow',s,black)
Priority(MaxPriority(w));
Screen('Flip', w)
[wx, wy] = RectCenter(rect);



if vpix_use == 1
    %VIEW PIXX SETUP
    Datapixx('Open');
    Datapixx('EnablePixelMode');  % to use topleft pixel to code trigger information, see https://vpixx.com/vocal/pixelmode/
    Datapixx('RegWr');
end


% TRIGGERS SETUP

% Top left pixel that controls triggers in PixelMode
if trigger_test == 0
    trigRect = [0 0 1 1];
    %centeredRect_trigger = CenterRectOnPointd(trigRect, 0.5, 0.5);
elseif trigger_test == 1
    trigRect = [0 0 100 100];
    %centeredRect_trigger = CenterRectOnPointd(trigRect, 25, 25);
end



%centeredRect_trigger = CenterRectOnPointd(baseRect_trigger, 0.5, 0.5);


% Define trigger pixels for all usable MEG channels
trig.ch224 = [4  0  0]; %224 meg channel
trig.ch225 = [16  0  0];  %225 meg channel
trig.ch226 = [64 0 0]; % 226 meg channel
trig.ch227 = [0  1 0]; % 227 meg channel
trig.ch228 = [0  4 0]; % 228 meg channel
trig.ch229 = [0 16 0]; % 229 meg channel
trig.ch230 = [0 64 0]; % 230 meg channel
trig.ch231 = [0 0  1]; % 231 meg channel

fields = fieldnames(trig); % Get the field names of the structure

time2trigger = 5;

escKey = KbName('ESCAPE');  % Define the ESC key

times = 3;

expStartTime = GetSecs();

lags = zeros(1,8);

for j = 1:times

    for i = 1:numel(fields)


        % Check for key press
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(escKey)
            disp('ESC key pressed. Exiting...');
            break;  % Exit the inner loop
        end


        fieldName = fields{i}; % Get the field name
        fieldValue = trig.(fieldName); % Get the value of the field
    
        fprintf('%s: [%d %d %d]\n', fieldName, fieldValue); % Print the field name and value
        
        message = ['One trigger every ', int2str(time2trigger),' seconds.' ...
            'Channel name getting triggered now: ', fieldName, 'Press Escape to cancel'];
        Screen('DrawText', w, message,  wx-250, wy, [255,255,255]);
        
        Screen('FillRect', w, fieldValue, trigRect);
        Screen('Flip', w);
        Screen('DrawText', w, message,  wx-250, wy, [255,255,255]);
        Screen('FillRect', w, black, trigRect);
        Screen('Flip', w);
        start_time = GetSecs()-expStartTime;
        WaitSecs(time2trigger);
        end_time = GetSecs()-expStartTime;

        lags(i) = end_time-start_time;

    end
end

Screen('CloseAll');

if vpix_use == 1
    %VIEW PIXX SETUP
    Datapixx('Close');
end