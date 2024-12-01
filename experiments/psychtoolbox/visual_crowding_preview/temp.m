
%%
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

%%
    stim_set = 'SET1' % Or 'SET1'
    stim_dir = dir(fullfile(stim_set, '*.jpg'));
    stim_fn = {stim_dir.name};



%%
    quest_dir_fn = 'QuestImages';
    quest_dir = dir(fullfile(quest_dir_fn, '*.jpg'));
    quest_fn = {quest_dir.name};
    quest_fn = quest_fn(randperm(length(quest_fn)));

    %%

    CP_table;


    
    %%
    goodTrial = 1;
    nBadTrials = 0;
    i_trial = 1;
    numTrials = size(expTable, 1);
    questIdx = 1;
    validTrialsIndex = true(size(expTable,1), 1);
    
    condition_first_while = size(expTable, 1);
    counter_iter = 0;
    fixation_long_enough = 1;
 
    % 52 is the counter condition
    % This loop will iterate as many numbers as the triggers
    % If i_trial is incremented by 1 at every loop pass, then the number of
    % iterations from this loop is 52
    
    goodTrial = 1;
    


    counts.ch224 = 0; 
    counts.ch225 = 0; 
    counts.ch226 = 0; 
    counts.ch227 = 0;
    counts.ch228 = 0;
    counts.ch229 = 0;
    counts.ch230 = 0;
    counts.ch231 = 0;
    
    counts.ch224 = counts.ch224+1;
    

    first_if_condition = round(size(expTable, 1)/3+1);
    responsetimeslow = 0;

   
  
    while i_trial <= size(expTable, 1)
    % In this while loop we trigger in MEG index 225, 226, 227, 228, 229,
    % 230
        
        counter_iter = counter_iter+1;
        
        if mod(i_trial, round(size(expTable, 1)/3+1)) == 0
            %Screen('DrawText', w, 'WELL DONE, TAKE A BREAK !',  wx-400, wy, [0 0 0]);
            %Screen('FillRect', w, fixColor, trigRect);
            % Correction
            %Screen('FillRect', w, black, trigRect);
            %Screen('Flip', w);
            %KbWait([], 2)
            disp ('Pause start')
        end



        conn = expTable.connection(i_trial);
        cwdg = expTable.crowding(i_trial);
        imgIdx = expTable.imageIndex(i_trial);

        preview_fn = sprintf('%s_conn_%d_cwdg_%d_%d.jpg', stim_set, conn, cwdg, imgIdx);
        imageFilePath = fullfile(stim_set, preview_fn);
        
        disp(imageFilePath)

        % If the file doesn't exist

        if ~isfile(imageFilePath)
            validTrialsIndex(i_trial)
            i_trial = i_trial + 1;
            continue;
            disp('File does not exist IF triggered')
        end
        

        previewMatrix = imread(fullfile(stim_set, preview_fn));
        %previewTexture = Screen('MakeTexture', w, previewMatrix);
        %targetTexture = previewTexture;

        % Trial settings for question/response
        question_fn = ['img_' num2str(i_trial) '.jpg'];

        %Fixation
        counts.ch225 = counts.ch225+1;
        
        while goodTrial
            noblink =1;
            good_fixation=1;
            if noblink ==1 && good_fixation ==1
                break;
            else
                % As long as there is blinks and the fixation is not good,
                % we are triggering ch225 MEG
                counts.ch225 = counts.ch225+1;
            end
        end

        %Preview and Cue
        counts.ch226 = counts.ch226+1;
        
        
        while goodTrial
            if noblink && good_fixation && fixation_long_enough
                counts.ch227 = counts.ch227+1;
                break;
            end
        end
        
        
        response = 8;
        
        while goodTrial

            counts.ch228 = counts.ch228+1;
            break;
        end

        counts.ch229 = counts.ch229+1;


        counts.ch230 = counts.ch230+1;

        if goodTrial ==1
            if responsetimeslow == 1
                disp('nothing')
            elseif response == 8 || response == 9
                i_trial = i_trial+1;
                % If the file exists, the number of i_trial is not increased
            end
        end




   end
    
   disp(['Number of iterations ', num2str(counter_iter)])
    
   disp(counts)

