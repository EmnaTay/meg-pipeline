% This is the original file that is causing the trigger error
% This file includes the 'outro' page/screen

% This paradigm file uses a LogFile to account for extra triggers 
% The LogFile logs all important events
% Added 'executedTrials' to ensure no repeats of trials

clearvars
Screen('Preference', 'SkipSyncTests', 1);
AssertOpenGL;

Datapixx('Open');

Datapixx('DisablePixelMode');
Datapixx('RegWr');

Datapixx('SetPropixxDlpSequenceProgram', 0);
Datapixx('RegWr');


% PARTICIPANT DATA
name1='Participant Data';
prompt1={'Subject Number', ...
    'Subject ID', ...
    'Sex (f/m)', ...
    'Age', ...
    'Task order'};
numlines1=1;
defaultanswer1={ '0', 'p', 'M', '0', '1'};
answer1=inputdlg(prompt1,name1,numlines1,defaultanswer1);
DEMO.num = str2double(answer1{1});
DEMO.ID  = answer1{2};
DEMO.sex = answer1{3};
DEMO.age = str2double(answer1{4});
DEMO.order = str2double(answer1{5});
DEMO.date = datetime;

logFilename = sprintf('trigger_log_subject_%s.txt', DEMO.ID);
logFile = fopen(logFilename, 'w');
fprintf(logFile, 'Trial\tChannel\tCondition\tTime\tImageName\tConditionLabel\tMessage\n');

fixColor = [0 0 0]; % Fixation color (black)
fixColorCue = [0 128 0];
fixBadColor = [255 0 0]; % Fixation bad color (red)
fixRadius = 10;
black = [0 0 0];
fixTolerance = 100; % 75 pixels -> 2 dva
targetTolerance = 100;
saccadeOffset = 305; % pixel -> 8 dva
targetDuration = .5; % seconds
saccThreshold = 7; % pixel -> 0.18 dva

try

    % Screen setup
    s = max(Screen('Screens'));
    % Set the background color to white during window initialization
    [w, rect] = Screen('OpenWindow', s, [255 255 255]); %,[200 200 1000 1000]);
    Priority(MaxPriority(w));
    Screen('BlendFunction', w, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    pixelSizes = Screen('PixelSizes', s);
    fps = Screen('FrameRate', w);
    ifi = Screen('GetFlipInterval', w);
    [wx, wy] = RectCenter(rect);

    fixRect = CenterRectOnPoint([0, 0, fixRadius*2, fixRadius*2], wx, wy);


    if length([answer1{1} answer1{2}]) > 4
        error('EYELINK FILENAMES NEED TO BE LESS THAN 9 CHARACTERS LONG')
    end

    % TRIGGERS SETUP
    trig.SYNCTIME = 0;
    trig.START = 1;
    trig.PREVIEW = 2;
    trig.SACCADE = 3;
    trig.TARGET = 4;
    trig.RESPONSE = 5;

    % EYE-TRACKING SETUP
    el = EyelinkInitDefaults(w);
    el.backgroundcolour = 255;
    el.foregroundcolour = 0;
    el.calibrationtargetcolour = [0 0 0];
    el.msgfontcolour = 0;
    EyelinkUpdateDefaults(el);

    if ~EyelinkInit() % 1 means enable dummy mode
        fprintf('Eyelink Init aborted.\n');
        Eyelink('Shutdown');
        Screen('CloseAll');
    end

    Eyelink('command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, rect(4)-1, rect(3)-1);

    % Link to edf data
    Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT'); WaitSecs(0.05);
    Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET'); WaitSecs(0.05);

    % Link data to Matlab
    Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT'); WaitSecs(0.05);
    Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT,HTARGET'); WaitSecs(0.05);
    Eyelink('command', 'link_event_data = GAZE,GAZERES,HREF,AREA,VELOCITY'); WaitSecs(0.05);

    edfFile = ['Subj' answer1{1} '.edf'];
    Eyelink('Openfile', edfFile);

    Eyelink('command', 'calibration_type = HV6'); WaitSecs(0.05);
    % Before recording, we place reference graphics on the host display
    % Must be offline to draw to EyeLink screen
    Eyelink('Command', 'set_idle_mode'); WaitSecs(0.05);

    EyelinkDoTrackerSetup(el); WaitSecs(0.05);

    trigger_test = 0;

    % Top left pixel that controls triggers in PixelMode
    if trigger_test == 0
        trigRect = [0 0 1 1];
        %centeredRect_trigger = CenterRectOnPointd(trigRect, 0.5, 0.5);
    elseif trigger_test == 1
        trigRect = [0 0 100 100];
        %centeredRect_trigger = CenterRectOnPointd(trigRect, 25, 25);
    end


    Screen('FillRect', w, black, trigRect);
    Screen('Flip', w);


    Datapixx('EnablePixelMode');  % to use topleft pixel to code trigger information, see https://vpixx.com/vocal/pixelmode/
    Datapixx('RegWr');


    % KEYBOARD SETUP
    responseKeys = {'c', 'v', 'a', 'y', 'n', 'return'}; % eyelink commands
    KbName('UnifyKeyNames');
    KbCheckList = [KbName('space'), KbName('ESCAPE'), KbName('leftarrow'), KbName('rightarrow')];
    for i = 1:length(responseKeys)
        KbCheckList = [KbName(responseKeys{i}), KbCheckList];
    end
    RestrictKeysForKbCheck(KbCheckList);
    ListenChar(-1)

    % Define trigger pixels for all usable MEG channels
    trig.ch224 = [4  0  0]; %224 meg channel
    trig.ch225 = [16  0  0];  %225 meg channel
    trig.ch226 = [64 0 0]; % 226 meg channel
    trig.ch227 = [0  1 0]; % 227 meg channel
    trig.ch228 = [0  4 0]; % 228 meg channel
    trig.ch229 = [0 16 0]; % 229 meg channel
    trig.ch230 = [0 64 0]; % 230 meg channel
    trig.ch231 = [0 0  1]; % 231 meg channel

    % Clear the screen with the background color (white)
    Screen('FillRect', w, [255 255 255]);
    Screen('FillRect', w, black, trigRect);
    Screen('Flip', w);


    if mod(DEMO.num,2) == 0 % if 0 -> even number
        stim_set = 'SET1';
    else                    % if 1 -> odd number
        stim_set = 'SET2';

    end

    stim_dir = dir(fullfile(stim_set, '*.jpg'));
    stim_fn = {stim_dir.name};

    quest_dir_fn = 'QuestImages';
    quest_dir = dir(fullfile(quest_dir_fn, '*.jpg'));
    quest_fn = {quest_dir.name};
    quest_fn = quest_fn(randperm(length(quest_fn)));

    CP_table;

    % START EXPERIMENT
    text = { 
        'You will see a fixation point in the middle of the screen. Please keep your eyes fixated on it.'
        'Keep your eyes fixated on the point until it turns green.'
        'When the point turns green, look at the wrod either to the left or righ of the fixation point.'
        'You will be prompted to answer the question "Is this  the same word you last saw?"'
        'You can answer with the yellow butto for "YES" or the red button for "NO".'
        'NOTE: The word will appear before the fixation point turns green. Please do not look at the word before the point turns to green.'
        ''
        };

    yPos = wy - 200;

    for i = 1:length(text)
        Screen('DrawText', w, text{i},  wx - 600, yPos, [0 0 0]);
        yPos = yPos + 50;
    end
    Screen('FillRect', w, black, trigRect);
    Screen('Flip', w);
    KbWait([], 2)

    fprintf(logFile, 'N/A\t224\tStart Experiment\t%f\tN/A\tN/A\tTriggering start of experiment\n', GetSecs());


    % Trigger 1
    Screen('FillRect', w, trig.ch224, trigRect);
    Screen('Flip', w);
    Screen('FillRect', w, black, trigRect);
    Screen('Flip', w);

    Eyelink('Command', 'SetOfflineMode');
    Eyelink('StartRecording');
    Screen('FillOval', w, fixColor, fixRect);
    Screen('FillRect', w, fixColor, trigRect);
    Screen('Flip', w);
    WaitSecs(2);
    trig.SYNCTIMEsecs = GetSecs();
    Eyelink('Message', 'TRIGGER %d', trig.SYNCTIME);
    eyeUsed = Eyelink('EyeAvailable');
    eyeUsed = eyeUsed + 1;

    goodTrial = 1;
    nBadTrials = 0;
    i_trial = 1;
    numTrials = size(expTable, 1);
    questIdx = 1;
    validTrialsIndex = true(size(expTable,1), 1);
    executedTrials = false(size(expTable, 1), 1);

    while i_trial <= size(expTable, 1)
            fprintf(logFile, '%d\tN/A\tN/A\t%f\tN/A\tN/A\tStarting trial\n', i_trial, GetSecs());

        % if executedTrials(i_trial)
        %     % Skip this trial since if it has already been executed
        %     i_trial = i_trial + 1;
        %     continue;
        % end

                % PAUSE
        if mod(i_trial, round(size(expTable, 1)/3+1)) == 0
            Screen('DrawText', w, 'WELL DONE, TAKE A BREAK !',  wx-400, wy, [0 0 0]);
            Screen('FillRect', w, fixColor, trigRect);
            Screen('Flip', w);
            KbWait([], 2)

        end

        if mod(DEMO.num, 2) == 0
            set = 'SET1';  % If subject number is even
        else
            set = 'SET2';  % If subject number is odd
        end
        conn = expTable.connection(i_trial);
        cwdg = expTable.crowding(i_trial);
        imgIdx = expTable.imageIndex(i_trial);

        preview_fn = sprintf('%s_conn_%d_cwdg_%d_%d.jpg', set, conn, cwdg, imgIdx);

        imageFilePath = fullfile(stim_set, preview_fn);

        if ~isfile(imageFilePath)
            validTrialsIndex(i_trial)
            i_trial = i_trial + 1;
            continue;
        end
        
        previewMatrix = imread(fullfile(stim_set, preview_fn));
        previewTexture = Screen('MakeTexture', w, previewMatrix);
        targetTexture = previewTexture;

        % Trial settings for question/response
        question_fn = ['img_' num2str(i_trial) '.jpg'];
        % questRect = CenterRectOnPoint([0 0 size(previewMatrix, 1)*2 size(previewMatrix, 2)], wx , wy);

        if expTable.preview(i_trial) == 0
            previewTexture = Screen('MakeTexture', w, fliplr(previewMatrix));
        end
        expTable.imageFn{i_trial} = preview_fn;

        if expTable.questionType(i_trial) == 0
            questionTexture = targetTexture;

        else
            if questIdx <= length(quest_fn)
                selectedTexture = quest_fn{questIdx};
                selectedTextureMatrix = imread(fullfile(quest_dir_fn, selectedTexture));
                questionTexture = Screen('MakeTexture', w, selectedTextureMatrix);
                questIdx = questIdx + 1;
            end
        end

        % OFFSCREEN

        wFixation = Screen('OpenOffscreenWindow', w, 255);
        % fixRect = CenterRectOnPoint([0, 0, fixRadius*2, fixRadius*2], wx, wy);
        Screen('FillOval', wFixation, black, fixRect);

        wPreview = Screen('OpenOffscreenWindow', w, 255);
        previewRect = CenterRectOnPoint([0 0 size(previewMatrix, 2) size(previewMatrix, 1)], wx+ saccadeOffset*expTable.side(i_trial), wy);
        Screen('FillOval', wPreview, black, fixRect);
        Screen('DrawTexture', wPreview, previewTexture, [], previewRect);

        wCue = Screen('OpenOffscreenWindow', w, 255);
        cueRect = CenterRectOnPoint([0 0 size(previewMatrix, 2) size(previewMatrix, 1)], wx+ saccadeOffset*expTable.side(i_trial), wy);
        Screen('FillOval', wCue, fixColorCue, fixRect);
        Screen('DrawTexture', wCue, previewTexture, [], cueRect);

        wTarget = Screen('OpenOffscreenWindow', w, 255);
        Screen('FillOval', wTarget, fixColorCue, fixRect);
        Screen('DrawTexture', wTarget, targetTexture, [], previewRect);

        wQuestion = Screen('OpenOffscreenWindow', w, 255);
        questRect = CenterRectOnPoint([0 0 size(previewMatrix, 2) size(previewMatrix, 1)], wx, wy);
        Screen('DrawTexture', wQuestion, questionTexture, [], questRect);
        Screen('DrawText', wQuestion, 'yes', wx - 305, wy + 150, black);
        Screen('DrawText', wQuestion, 'no', wx + 305, wy + 150, black);

        if i_trial <= size(expTable, 1)
            imageName = expTable.imageFn{i_trial};  % Get the image name for this trial

            % Extract the condition label from the image name
            conditionPattern = 'cwdg_(\d+)';  % Regex pattern to match 'cwdg_X'
            conditionMatch = regexp(imageName, conditionPattern, 'tokens');
            if ~isempty(conditionMatch)
                conditionLabel = conditionMatch{1}{1};  % Extract the condition number (e.g., '3')
            else
                conditionLabel = 'Unknown';  % In case the condition can't be determined
            end

        else
            imageName = 'N/A';  % No image available (indicating an extra trigger)
            conditionLabel = 'N/A';  % No condition for extra triggers
        end


        % FIXATION
        goodTrial = 1;
        errorMsg = 'BAD TRIAL';

        Screen('DrawTexture', w, wFixation);
        Screen('FillRect', w, trig.ch225, trigRect);
        Screen('Flip', w);
        Screen('DrawTexture', w, wFixation);
        Screen('FillRect', w, fixColor, trigRect);
        Screen('Flip', w);

        fixOnsetTime = GetSecs();
        expTable.fixStartTime(i_trial) = GetSecs();
        Eyelink('Message', 'TRIGGER %d', trig.START);
        expTable.fixDuration(i_trial) = (1000+randperm(500,1))/1000; % random fixation duration
        eyeX = nan; eyeY = nan;
        disp('DEBUG 3')
        while goodTrial
            [~,~, keyCode] = KbCheck();
            if find(keyCode) == KbName('escape')
                ShowCursor()
                RestrictKeysForKbCheck([]);
                Screen(w,'Close');
                sca;
                ListenChar(0)
                return;
            end

            if Eyelink('NewFloatSampleAvailable')
                eyeSample = Eyelink('NewestFloatSample');
                eyeX = eyeSample.gx(eyeUsed);
                eyeY = eyeSample.gy(eyeUsed);

                if eyeX~=el.MISSING_DATA && eyeY~=el.MISSING_DATA % no blinks
                    dist_center = sqrt( (eyeX-wx)^2 + (eyeY-wy)^2 );
                    if dist_center < fixTolerance % fixation is good
                        if GetSecs() - expTable.fixStartTime(i_trial) > expTable.fixDuration(i_trial) % fixation is long enough
                            break;
                        end
                    else
                        for i=1:3
                            Screen('FillRect', w, fixBadColor, fixRect);
                            Screen('FillRect', w, fixColor, trigRect);

                            Screen('Flip', w);
                            WaitSecs(.1);
                            Screen('FillRect', w, fixColor, trigRect);

                            Screen('Flip', w);
                            WaitSecs(.1);
                        end

                        Screen('DrawTexture', w, wFixation);
                        Screen('FillRect', w, trig.ch225, trigRect);
                        Screen('Flip', w);
                        Screen('DrawTexture', w, wFixation);
                        Screen('FillRect', w, fixColor, trigRect);
                        Screen('Flip', w);

                        expTable.fixStartTime(i_trial) = GetSecs();
                        Eyelink('Message', 'TRIGGER %d', trig.START);
                    end
                else % blink
                    expTable.fixStartTime(i_trial) = GetSecs();
                    Eyelink('Message', 'TRIGGER %d', trig.START);
                end
            end

%             if GetSecs() - fixOnsetTime > 10
%                 errorMsg = 'BAD FIXATION';
%                 Eyelink('StopRecording');
%                 EyelinkDoTrackerSetup(el);
%                 Eyelink('StartRecording');
%                 goodTrial = 0;
%             end
        end


        % PREVIEW AND CUE
        % Condition-based MEG trigger channel
        if strcmp(conditionLabel, '1')
            currentTriggerChannel = trig.ch226;  % Condition 1 -> Channel 226
        elseif strcmp(conditionLabel, '2')
            currentTriggerChannel = trig.ch227;  % Condition 2 -> Channel 227
        elseif strcmp(conditionLabel, '3')
            currentTriggerChannel = trig.ch228;  % Condition 3 -> Channel 228
        end

        % Trigger for preview image (Channel 226)
        Screen('DrawTexture', w, wPreview);
        if strcmp(imageName, 'N/A')
            fprintf(logFile, '%d\t%d\tPreview Image\t%f\t%s\t%s\tExtra trigger - no image\n', i_trial, currentTriggerChannel, GetSecs(), imageName, conditionLabel);
        else
            fprintf(logFile, '%d\t%d\tPreview Image\t%f\t%s\t%s\tTriggering preview image\n', i_trial, currentTriggerChannel, GetSecs(), imageName, conditionLabel);
        end
        Screen('FillRect', w, currentTriggerChannel, trigRect);
        Screen('Flip', w);
        Screen('DrawTexture', w, wPreview);
        Screen('FillRect', w, black, trigRect);
        Screen('Flip', w);

        expTable.previewOnsetTime(i_trial) = GetSecs();
        Eyelink('Message', 'TRIGGER %d', trig.PREVIEW);
        saccTrigger = 0;

        while goodTrial
            [~,~, keyCode] = KbCheck();
            if find(keyCode) == KbName('escape')
                ShowCursor()
                RestrictKeysForKbCheck([]);
                Screen(w,'Close');
                sca;
                ListenChar(0)
                return;
            end

            if Eyelink('NewFloatSampleAvailable')
                eyeSample = Eyelink('NewestFloatSample');
                eyeX = eyeSample.gx(eyeUsed);
                eyeY = eyeSample.gy(eyeUsed);
                disp(['EyeX: ', num2str(eyeX)]);

                if eyeX~=el.MISSING_DATA && eyeY~=el.MISSING_DATA % no blinks
                    dist_center = sqrt( (eyeX-wx)^2 + (eyeY-wy)^2 );
                    if dist_center < fixTolerance % fixation is good
                       if GetSecs() - expTable.fixStartTime(i_trial) > expTable.fixDuration(i_trial)+.5 % fixation is long enough
                            if strcmp(imageName, 'N/A')
                                fprintf(logFile, '%d\t229\tCue\t%f\t%s\t%s\tExtra trigger - no image\n', i_trial, GetSecs(), imageName, conditionLabel);
                            else
                                fprintf(logFile, '%d\t229\tCue\t%f\t%s\t%s\tTriggering preview image\n', i_trial, GetSecs(), imageName, conditionLabel);
                            end
                            Screen('DrawTexture', w, wCue);
                            Screen('FillRect', w, trig.ch229, trigRect);
                            Screen('Flip', w);
                            Screen('DrawTexture', w, wCue);
                            Screen('FillRect', w, black, trigRect);
                            Screen('Flip', w);
                            break;
                        end
%                     else
%                         goodTrial = 0;
                    end
%                 else % blink
%                     goodTrial = 0;
                end
            end
        end


        disp('DEBUG 4')
        while goodTrial
            % detect saccadeOnset with threshold
            if Eyelink('NewFloatSampleAvailable')
                eyeSample = Eyelink('NewestFloatSample');
                newEyeX = eyeSample.gx(eyeUsed);
                disp(['newEyeX: ', num2str(newEyeX)]); % Debugging output

                if abs(newEyeX - eyeX) > saccThreshold % if neeyeX > over the imaginary boundary
                    saccTrigger = saccTrigger + 1;
                    if saccTrigger > 1
                        expTable.saccadeOnsetTime(i_trial) = GetSecs();
                        disp('Saccade detected'); % Debugging output

                        Eyelink('Message', 'TRIGGER %d', trig.SACCADE);
                        if strcmp(imageName, 'N/A')
                            fprintf(logFile, '%d\tN/A\tSaccade\t%f\t%s\t%s\tExtra trigger - no image\n', i_trial, GetSecs(), imageName, conditionLabel);
                        else
                            fprintf(logFile, '%d\tN/A\tSaccade\t%f\t%s\t%s\tTriggering preview image\n', i_trial, GetSecs(), imageName, conditionLabel);
                        end
                        Screen('FillRect', w, black, trigRect);
                        Screen('Flip', w);
                        Screen('FillRect', w, black, trigRect);
                        Screen('Flip', w);
                        break;
                    end
                else
                    disp('Saccade not detected');
                    saccTrigger=0;
                end
                eyeX = newEyeX;
            end
        end

        % TARGET
        Screen('DrawTexture', w, wTarget);
        if strcmp(imageName, 'N/A')
            fprintf(logFile, '%d\t230\tTarget Image\t%f\t%s\t%s\tExtra trigger - no image\n', i_trial, GetSecs(), imageName, conditionLabel);
        else
            fprintf(logFile, '%d\t230\tTarget Image\t%f\t%s\t%s\tTriggering preview image\n', i_trial, GetSecs(), imageName, conditionLabel);
        end
        Screen('FillRect', w, trig.ch230, trigRect);
        Screen('Flip', w);
        Screen('DrawTexture', w, wTarget);
        Screen('FillRect', w, black, trigRect);
        Screen('Flip', w);

        % Set trigger back to black

        expTable.targetOnsetTime(i_trial) = GetSecs();
        Eyelink('Message', 'TRIGGER %d', trig.TARGET);

        while GetSecs() - expTable.targetOnsetTime(i_trial) < targetDuration
            [~, ~, keyCode] = KbCheck();
            if find(keyCode) == KbName('escape')
                ShowCursor();
                RestrictKeysForKbCheck([]);
                Screen('CloseAll');
                sca;
                ListenChar(0);
                return; % Exit the script
            elseif Eyelink('NewFloatSampleAvailable')
                eyeSample = Eyelink('NewestFloatSample');
                eyeX = eyeSample.gx(eyeUsed);
                eyeY = eyeSample.gy(eyeUsed);

                if eyeX~=el.MISSING_DATA && eyeY~=el.MISSING_DATA % if there are no blinks
                    % dist_target = sqrt( (eyeX- (wx+saccadeOffset*expTable.side(i_trial)) )^2 + (eyeY-wy)^2 );
                    dist_target = eyeX - (wx+saccadeOffset*expTable.side(i_trial));
%                     disp(['dist_target: ', num2str(dist_target)]);
                    if dist_target < fixTolerance % and the saccade landed inside the word
                        if GetSecs() - expTable.targetOnsetTime(i_trial) > targetDuration % and they fixated the word long enough
                            break;
                        end
%                     else
%                         errorMsg = 'BAD SACCADE';
%                         goodTrial = 0;
                    end
%                 else % blink
%                     errorMsg = 'BAD BLINK';
%                     goodTrial = 0;
                end
            end
        end

        Screen('FillRect', w, [255 255 255]);
        Screen('FillRect', w, black, trigRect);
        Screen('Flip', w);
        WaitSecs(1)


        % RESPONSE
        Screen('DrawTexture', w, wQuestion);
        Screen('FillRect', w, black, trigRect);
        Screen('Flip', w);
        Screen('DrawTexture', w, wQuestion);
        Screen('FillRect', w, black, trigRect);
        Screen('Flip', w);
        
        expTable.questionOnsetTime(i_trial) = GetSecs();
        % expTable.responseOnsetTime(i_trial) = GetSecs();

        if goodTrial
            nBadTrials = 0;
            [response, ResponseTime] = getButton();
            
            if find(keyCode) == KbName('escape') % exit response
                ShowCursor();
                RestrictKeysForKbCheck([]);
                Screen('CloseAll');
                sca;
                ListenChar(0);
                return; % Exit the script

            elseif response == 8 || response == 9 %good response 8 is yellow (yes)/ 9 is red (no)
                Eyelink('Message', 'TRIGGER %d', trig.RESPONSE);


                % Response correctness
                % if keyCode(KbName('y'))
                %     response = num2str('y');
                % elseif keyCode(KbName('n'))
                %     response = num2str('n');
                % end

                expTable.response(i_trial) = response;
                expTable.responseOnsetTime(i_trial) = ResponseTime;

                if (targetTexture == questionTexture && response == 8) || (targetTexture ~= questionTexture && response == 9)
                    expTable.correctness(i_trial) = 1; % response correct
                else
                    expTable.correctness(i_trial) = 0; % response not correct
                end

                Eyelink('Message',  ['COND ' num2str(expTable.preview(i_trial)) num2str(expTable.side(i_trial)+1) num2str(expTable.crowding(i_trial))]);

                i_trial = i_trial + 1;
                Eyelink('command', 'record_status_message "TRIAL %d/%d"', i_trial, size(expTable, 1));
            end
        else
            disp(errorMsg)
            Eyelink('Message', ['BAD :' errorMsg]);
            expTable(end + 1, :) = expTable(i_trial, :);
            expTable(i_trial, :) = [];
            nBadTrials = nBadTrials + 1;
            Eyelink('command', ['record_status_message "TRIAL BAD :' errorMsg '" ']);
        end

        fprintf(logFile, '%d\tEndTrial\tN/A\t%f\t%s\t%s\tEnding trial\n', i_trial, GetSecs(), imageName, conditionLabel);

        Screen('FillRect', w, [255 255 255]);
        Screen('FillRect', w, black, trigRect);
        Screen('Flip', w);
        WaitSecs(1)

    end

    Screen('DrawText', w, 'Congrats! You are done.',  wx-400, wy, [0 0 0]);
    Screen('FillRect', w, fixColor, trigRect);
    Screen('Flip', w);
    WaitSecs(5);

    expTable = expTable(validTrialsIndex, :);

    Datapixx('DisablePixelMode');
    Datapixx('RegWr');
    Datapixx('Close');

    % SAVE DATA
    EXP.DEMO = DEMO;
    EXP.data = expTable;
    EXP.trig = trig;
    EXP.stim = stim_fn;
    save(['Sub' answer1{1} '.mat'], 'EXP')

    % SAVE EYE DATA
    Eyelink('StopRecording');
    Eyelink('CloseFile');
    Eyelink('ReceiveFile');
    Eyelink('ShutDown');

    Datapixx('DisablePixelMode');
    Datapixx('RegWr');
    Datapixx('Close');

    % FINISH EXPERIMENT
    ShowCursor();
    RestrictKeysForKbCheck([]);
    Screen('CloseAll');
    sca;
    ListenChar(0);

catch
    % FINISH EXPERIMENT
    ShowCursor();
    RestrictKeysForKbCheck([]);
    Screen('CloseAll');
    sca;
    ListenChar(0);
    rethrow(lasterror);
end
fclose(logFile);
