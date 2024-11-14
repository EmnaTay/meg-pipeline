
% Vpixx BOOLS

VPIXX_USE = 1; % 0 if vpixx is not conected
TRIGGER_TEST = 1;


%Trigger header

if VPIXX_USE == 1
    %VIEW PIXX SETUP
    Datapixx('Open');
    Datapixx('EnablePixelMode');  % to use topleft pixel to code trigger information, see https://vpixx.com/vocal/pixelmode/
    Datapixx('RegWr');
end


% Define trigger pixels for all usable MEG channels
trig.ch224 = [4  0  0]; %224 meg channel
trig.ch225 = [16  0  0];  %225 meg channel
trig.ch226 = [64 0 0]; % 226 meg channel
trig.ch227 = [0  1 0]; % 227 meg channel
trig.ch228 = [0  4 0]; % 228 meg channel
trig.ch229 = [0 16 0]; % 229 meg channel
trig.ch230 = [0 64 0]; % 230 meg channel
trig.ch231 = [0 0  1]; % 231 meg channel

% Trigger example

% Top left pixel that controls triggers in PixelMode
if TRIGGER_TEST == 0
    trigRect = [0 0 1 1];
    %centeredRect_trigger = CenterRectOnPointd(trigRect, 0.5, 0.5);
elseif TRIGGER_TEST == 1
    trigRect = [0 0 100 100];
    %centeredRect_trigger = CenterRectOnPointd(trigRect, 25, 25);
end



if VPIXX_USE == 1
    %VIEW PIXX SETUP
    Datapixx('Close');
end




