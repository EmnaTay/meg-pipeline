
% FIXATION CROSS 
fixationSize = 12; fixationWidth = 5; 
Screen('DrawLine', window, white, xCenter-fixationSize, ...
    yCenter, xCenter+fixationSize, yCenter, fixationWidth);
Screen('DrawLine', window, white, xCenter, yCenter-fixationSize,...
    xCenter, yCenter+fixationSize, fixationWidth);

% FIXATION DOT 
% fixationDotRect = [xCenter - fixationSize, yCenter - fixationSize, ...
%     xCenter + fixationSize, yCenter + fixationSize]; 
% fixationDotRect = CenterRectOnPointd(fixationDotRect,xCenter,yCenter); 
% Screen('FillOval', window, white, fixationDotRect)
