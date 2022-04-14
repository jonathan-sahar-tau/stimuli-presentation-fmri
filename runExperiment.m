function runExperiment(subjectId, partToRun, singleRun)
    close all;
    sca
    clc
    pause on
    addpath('../utils');
    rng(0,'twister');

    %% constants

    %% control which parts of the experiment to run


    if ~exist('partToRun','var')
        % third parameter does not exist, so default it to
        partToRun = 'all';
    end
    if ~exist('singleRun','var')
        % third parameter does not exist, so default it to
        singleRun = 0;
    end

    runWithDisplay = 1;
    runLocalizer = 0;
    runFirstPart = 0;
    runSecondPart = 0;

    switch (partToRun)
      case 'all'
        runLocalizer = 1;
        runFirstPart = 1;
        runSecondPart = 1;
      case 'localizer'
        runLocalizer = 1;
      case 'shapes'
        runFirstPart = 1;
      case 'classification'
        runSecondPart = 1;
    end


    numRuns = 2;
    numBlocks = 4;
    numImagesPerBlock = 4;
    assert(mod(numImagesPerBlock,2) == 0); % otherwise blocks will not be synced to Tr, because of the 0.5 sec wait between images
    numCatchTrialBlocks = 2;
    catchTrialBlockLocations = [randi([1, round(numBlocks/2)], 1), randi([round(numBlocks/2) + 1, numBlocks], 1)]
    blocks = [[1 3 5 7]; [2 4 6 8]] % two typse of 4-image blocks for first part
                                    % duration of each image display
    dispDuration= 1;
    % duration to wait between shape displays in a block
    betweenShapesDuration = 0.5;
    % duration to wait betewen blocks
    blockWaitDuration=8;

    blockAndFixationDuration = numImagesPerBlock *  ...
        (dispDuration + betweenShapesDuration) +...
        blockWaitDuration;

    %times for starts of block displays
    runTiming = [0:blockAndFixationDuration:blockAndFixationDuration * (numBlocks - 1)]

    numRunsClass = 2;
    numBlocksClass = 6;
    assert(mod(numBlocksClass, 3) == 0);
    numImagesPerClassificationBlock = 6;
    catchTrialBlockLocationsClass = [randi([1, numBlocksClass/2], 1),...
                                               randi([numBlocksClass/2 + 1, numBlocksClass], 1)]
    % randsample(2:numBlocks-1,numCatchTrialBlocks)

    dispDurationClass= 0.75;
    % duration to wait between same-shape displays in a clssification block
    betweenShapesDurationClass = 0.25;
    % duration to wait betewen blocks
    blockWaitDurationClass=8;

    %times for starts of block displays
    blockAndFixationDurationClass = numImagesPerClassificationBlock *  ...
        (dispDurationClass + betweenShapesDurationClass) +...
        blockWaitDurationClass;

    runTimingClass = [0:blockAndFixationDurationClass:blockAndFixationDurationClass * (numBlocks - 1)]

    numBlocksLocalizer = numBlocks;
    numImagesPerBlockLocalizer = numImagesPerBlock;
    runTimingLocalizer = [0:blockAndFixationDuration:blockAndFixationDuration * (numBlocksLocalizer- 1)]

    % set the parameters of the fixation cross
    fixationCrossSize = 20; %size of fixation cross in pixels
    fixationCoords = [[-fixationCrossSize fixationCrossSize 0 0]; [0 0 -fixationCrossSize fixationCrossSize]];%setting fixation point coordinations
    lineWidthFixation = 5; %line width of fixaton cross in pixels
    stimSize=[0 0 100 100]; %Set Stimulus Dimantions [top-left-x, top-left-y, bottom-right-x, bottom-right-y].
                            % duration of each image display

    if singleRun
        numRuns = 1;
        numRunsClass = 1;
    end


    %% initiate psychtoolbox
    if runWithDisplay
        [window, xCenter, yCenter, black, white] = initScreen();
    end


    KbName('UnifyKeyNames');
    % specify key names of interest
    activeKeys = [KbName('ESCAPE') KbName('t') KbName('SPACE')];
    % activeKeys = [KbName('LeftArrow') KbName('RightArrow')];
    % restrict the keys for keyboard input to the keys we want
    % RestrictKeysForKbCheck(activeKeys);
    % suppress echo to the command line for keypresses
    % ListenChar(2);

    %% load images of shapes
    % images = loadImages('/mnt/g/My Drive/Msc neuroscience/lab - mukamel/code/stimuli-presentation-for-fMRI/shape-images/')
    images = loadImages('.\shape-images\centered\150%\')
    localizerImages = loadImages('.\shape-images\checkerboard\')

    helloImage = imread('.\instructions\hello.png');
    helloImage = 1 - double(logical(helloImage));

    allDoneImage = imread('.\instructions\allDone.png');
    allDoneImage = 1 - double(logical(allDoneImage));

    localizerImage = imread('.\instructions\localizer.png');
    localizerImage = 1 - double(logical(localizerImage));

    localizerDoneImage = imread('.\instructions\localizerDone.png');
    localizerDoneImage = 1 - double(logical(localizerDoneImage));

    allShapesRunDoneImage = imread('.\instructions\allShapesRunDone.png');
    allShapesRunDoneImage = 1 - double(logical(allShapesRunDoneImage));

    allShapesPartDoneImage = imread('.\instructions\allShapesPartDone.png');
    allShapesPartDoneImage = 1 - double(logical(allShapesPartDoneImage));

    allShapesInstructionsImage = imread('.\instructions\allShapesInstructions.png');
    allShapesInstructionsImage = 1 - double(logical(allShapesInstructionsImage));

    classificationRunDoneImage = imread('.\instructions\classificationRunDone.png');
    classificationRunDoneImage = 1 - double(logical(classificationRunDoneImage));

    classificationInstructionsImage = imread('.\instructions\classificationInstructions.png');
    classificationInstructionsImage = 1 - double(logical(classificationInstructionsImage));


    %% which subject are we running? keep its stats
    % load('./subjectData/latestSubjectId.mat')
    % subjectId = subjectId + 1;
    % save ./subjectData/latestSubjectId.mat subjectId;
    i = 0;
    logFile = "log_" + subjectId + ".mat"
    while isfile(logFile)
        i = i + 1;
        logFile = "log_" + subjectId + "_" + i + ".mat"
    end

    runLog = {};
    runLogClassification = {};


    blockStartTimes = [];
    blockStartTimesClass = [];
    blockStartTimes_localizer = [];

    blockEndTimes = [];
    blockEndTimesClass = [];
    blockEndTimes_localizer = [];

    runStartTimes = [];
    runStartTimesClass = [];
    runStartTimes_localizer = [];

    runEndTimes = [];
    runEndTimesClass = [];
    runEndTimes_localizer = [];

    imageStartTimes_localizer = [];
    imageStartTimes = [];
    imageStartTimesClass = [];

    imageEndTimes_localizer = [];
    imageEndTimes = [];
    imageEndTimesClass = [];

    imageIndex = [];
    imageIndexClass = [];

    catchTrialIndex = zeros(1, numBlocks);
    catchTrialIndex(1,catchTrialBlockLocations) = 1;

    catchTrialIndexClass = zeros(1, numBlocksClass);
    catchTrialIndexClass(1,catchTrialBlockLocationsClass) = 1;

    %HideCursor

    Screen('PutImage', window, helloImage); % put image on screen
    Screen('Flip', window);

    waitForSpace()

    if runLocalizer
        %% run a localizer run
        try

            Screen('PutImage', window, localizerImage); % put image on screen
            Screen('Flip', window);

            waitForSpace()
            waitForMRI();
            startTic = GetSecs;
            % start each run with a rest period

            Screen('DrawLines', ...
                   window, ...
                   fixationCoords,...
                   lineWidthFixation,...
                   black,...
                   [xCenter yCenter],...
                   2);
            Screen('Flip', window);
            waitForTimeOrEsc(blockWaitDuration);

            for i=1:numBlocksLocalizer
                imageIndices = randperm(numImagesPerBlockLocalizer); % permute the images

                % we have two types of blocks, each containing 4 images -
                % either odd and even indexed images of the original 8.
                % Display the two types alternatingly, and shuffle within the block
                actualImageIndices = blocks(mod(i,2) + 1, :);
                actualImageIndices = actualImageIndices(imageIndices);
                imageIndex = [imageIndex actualImageIndices];

                %log the start of this block
                blockStartTimes_localizer(1,end+1)= GetSecs - startTic;

                for imgIdx = imageIndices
                    % iterate over block images
                    img = localizerImages{imgIdx};
                    Screen('PutImage', window, img); % put image on screen
                                                     % Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);

                    imageStartTimes_localizer(1,end+1)= GetSecs - startTic;
                    Screen('Flip', window);

                    waitForTimeOrEsc(dispDuration);

                    Screen(window,'FillRect') % clear the screen between shapes
                    Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);

                    Screen('Flip', window);
                    imageEndTimes_localizer(1,end+1)= GetSecs - startTic;

                    waitForTimeOrEsc(betweenShapesDuration);

                end % images in block
                    % log the end of this block:
                blockEndTimes_localizer(1,end+1)= GetSecs - startTic;

                Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
                Screen('Flip', window);

                % force the last wait to end exactly when we want the next block to start.
                waitForTimeOrEsc(blockWaitDuration);

                % waitForTimeOrEsc(runTiming(i + 1), 1, startTic);

                fprintf('finished block %d\n', i);
            end % blocks in run
        catch exp % catch an ESC meant to stop the script
                  %             rethrow(exp)
        end

        runEndTimes_localizer(1,end+1)= GetSecs - startTic;
        Screen('PutImage', window, localizerDoneImage); % put image on screen
        Screen('Flip', window);
        waitForSpace()
    end %if localizer

    if runFirstPart

        %% run the experiment - part 1
        try
            Screen('PutImage', window, allShapesInstructionsImage); % put image on screen
            Screen('Flip', window);
            for run = 1:numRuns

                waitForSpace()
                waitForMRI();

                startTic = GetSecs;

                runStartTimes(1,end+1)= GetSecs - startTic;
                % start each run with a rest period
                Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);

                Screen('Flip', window);
                waitForTimeOrEsc(blockWaitDurationClass);

                for i=1:numBlocks
                    imageIndices = randperm(numImagesPerBlock); % permute the images
                                                                % if it's a catch trial - double one of the images
                    if ismember(i, catchTrialBlockLocations);
                        doubledIndex = randi([3,numImagesPerBlock], 1);
                        imageIndices(doubledIndex) = ...
                            imageIndices(doubledIndex - 1);
                    end

                    % we have two types of blocks, each containing 4 images -
                    % either odd and even indexed images of the original 8.
                    % Display the two types alternatingly, and shuffle within the block
                    actualImageIndices = blocks(mod(i,2) + 1, :);
                    actualImageIndices = actualImageIndices(imageIndices);
                    imageIndex = [imageIndex actualImageIndices];

                    %log the start of this block
                    blockStartTimes(1,end+1)= GetSecs - startTic;

                    for imgIdx = imageIndices
                        % iterate over block images
                        img = images{imgIdx};
                        Screen('PutImage', window, img); % put image on screen
                        Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);

                        imageStartTimes(1,end+1)= GetSecs - startTic;
                        Screen('Flip', window);

                        waitForTimeOrEsc(dispDuration);

                        Screen(window,'FillRect') % clear the screen between shapes
                        Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);

                        Screen('Flip', window);
                        imageEndTimes(1,end+1)= GetSecs - startTic;

                        waitForTimeOrEsc(betweenShapesDuration);

                    end % images in block
                        % log the end of this block:
                    blockEndTimes(1,end+1)= GetSecs - startTic;

                    Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
                    Screen('Flip', window);
                    waitForTimeOrEsc(blockWaitDuration);

                    % force the last wait to end exactly when we want the
                    % next block to start.
                    % waitForTimeOrEsc(runTiming(i + 1), 1, startTic);
                    fprintf('finished block %d\n', i);
                end % blocks in run
                fprintf('jonathan II\n', run);
                fprintf('finished run %d\n', run);
                runLog{run}.blockStartTimes = blockStartTimes;
                runLog{run}.blockEndTimes = blockEndTimes;
                runLog{run}.catchTrialIndex = catchTrialIndex;

                runEndTimes(1,end+1)= GetSecs - startTic;
                Screen('PutImage', window, allShapesRunDoneImage); % put image on screen
                Screen('Flip', window);
            end % runs
        catch exp % catch an ESC meant to stop the script
                  %             rethrow(exp)
        end
        Screen('PutImage', window, allShapesPartDoneImage); % put image on screen
        Screen('Flip', window);
        waitForSpace()

    end % if first part


    if runSecondPart
        %% load confusion matrix
        confusionMatPath = "confusion-matrix-example.csv";
        CM = csvread(confusionMatPath);
        avgCM = 0.5 * (CM + CM'); % consider the measure of confusion between two shapes as the average of a being confused for B and B for A
        avgCM = avgCM .* ~eye(size(avgCM)); % zero out the diag
        avgCM(avgCM == 0) = NaN; % replace zeros with NaNs

        %  get the running index of the max and min confusions
        [v, max_i] = max(avgCM(:));

        % get the proper indices (x,y) from the running index
        [x, mostConfusedWithx] = ind2sub(size(avgCM), max_i); %the most confused pair
        mostConfusedPair = [x, mostConfusedWithx];

        [v, leastConfusedWithx] = min(avgCM(x,:));
        leastConfusedPair = [x, leastConfusedWithx];


        %% run the experiment - part 2
        try

            indexPairs = [mostConfusedPair; leastConfusedPair];
            Screen('PutImage', window, classificationInstructionsImage); % put image on screen
            Screen('Flip', window);

            for run = 1:numRunsClass

                waitForSpace()
                waitForMRI();
                startTic = GetSecs;
                runStartTimesClass(1,end+1)= GetSecs - startTic;

                % start each run with a rest period
                Screen('DrawLines', window, fixationCoords, lineWidthFixation, ...
                       black, [xCenter yCenter], 2);
                Screen('Flip', window);
                waitForTimeOrEsc(blockWaitDurationClass);

                % each run contains two cycles of blocks -
                % with the most- and least-confused shapes with regard to x
                % (one of the pair of most confused shapes globally)
                for pair = 1:size(indexPairs,1)
                    indexPair = indexPairs(pair,1:size(indexPairs,1));
                    fprintf("currently running blocks of shapes: %d & %d\n", indexPair)
                    % every block is either 1 or 2, which is the index of the
                    % (single) shape that appears throughout the block.
                    % the first index belongs to x - the shared shape between all
                    % runs, so we give it only 2/3 of the blocks in each run to
                    % get an overall number of blocks for each shape.
                    blockIndices = [indexPair(1) * ones(1, numBlocksClass/3),...
                                    indexPair(2) * ones(1,numBlocksClass*2/3)];

                    blockIndices = blockIndices(randperm(length(blockIndices))); % shuffle the blocks
                    for i=1:numBlocksClass
                        % create the indices to use for displaying the shape(s)
                        % in this block
                        imageIndices = repmat(blockIndices(i), 1, ...
                                              numImagesPerClassificationBlock);
                        if ismember(i, catchTrialBlockLocationsClass)
                            % if it's a catch trial - change one of the images
                            % to the the other shape since the sum of the
                            % indices of the shapes is constant, we get the other
                            % shape by subtracting from the total
                            otherShapeIndex = sum(indexPair) - blockIndices(i);
                            catchImageIndex = randi([2,numImagesPerClassificationBlock], 1);
                            imageIndices(catchImageIndex) = otherShapeIndex;
                        end

                        imageIndexClass = [imageIndexClass imageIndices];

                        % log the start of this block
                        blockStartTimesClass(1, end+1) = GetSecs - startTic;
                        for imgIdx = imageIndices % iterate over block images
                            img = images{imgIdx};
                            Screen('PutImage', window, img); % put image on screen
                            Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);

                            Screen('Flip', window);
                            imageStartTimesClass(1,end+1)= GetSecs - startTic;

                            waitForTimeOrEsc(dispDurationClass);

                            Screen(window,'FillRect') % clear the screen between shapes
                            Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
                            Screen('Flip', window);
                            imageEndTimesClass(1,end+1)= GetSecs - startTic;

                            waitForTimeOrEsc(betweenShapesDurationClass);

                        end % images in block

                        % log the end of this block
                        blockEndTimesClass(1, end+1) = GetSecs - startTic;
                        Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
                        Screen('Flip', window);
                        waitForTimeOrEsc(blockWaitDurationClass);
                        % waitForTimeOrEsc(runTimingClass(i + 1), 1, startTic); %force the
                        last wait

                    end % blocks in image pair
                end % image pairs in run

                runLogClassification{run}.blockStartTimesClass= blockStartTimesClass;
                runLogClassification{run}.blockEndTimesClass= blockEndTimesClass;
                runLogClassification{run}.imageIndexClass= imageIndexClass;

                runEndTimesClass(1,end+1)= GetSecs - startTic;
                Screen('PutImage', window, classificationRunDoneImage); % put image on screen
                Screen('Flip', window);

            end % runs
        catch exp % catch an ESC meant to stop the script
                  %rethrow(exp)
        end
    end % if second part

    Screen('PutImage', window, allDoneImage); % put image on screen
    Screen('Flip', window);

    waitForSpace()
    Screen('CloseAll')
    ShowCursor
    save (logFile, 'runLog', 'runLogClassification')

    %     RestrictKeysForKbCheck([]);
    DisableKeysForKbCheck([]);
end

function images = loadImages(dir)
    if ~isfolder(dir)
        errorMessage = sprintf('Error: The following folder does not exist:\n%s', dir);
        uiwait(warndlg(errorMessage));
        return;
    end
    imageDS = imageDatastore(dir,"FileExtensions",".png");
    images = readall(imageDS);
end


function [window, xCenter, yCenter, black, white] = initScreen()
    Screen('Preference', 'VisualDebuglevel', 3); %No PTB intro screen
    Screen('Preference', 'SkipSyncTests', 1); %change to 0 in real experiment
    PsychDefaultSetup(2); % call some default settings for setting up Psychtoolbox
    screens = Screen('Screens');
    screenNumber = max(screens) % - 1 for showing on other screen;
    white = WhiteIndex(screenNumber);
    black = BlackIndex(screenNumber);
    green=[0,1,0];
    [window, windowRect] = PsychImaging('OpenWindow', screenNumber, white);
    Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    [screenXpixels, screenYpixels] = Screen('WindowSize', window); %get the size of the scrren in pixel
    [xCenter, yCenter] = RectCenter(windowRect); % Get the centre coordinate of the window in pixels
                                                 % text preferences
    s = Screen('TextSize', window, 30);
end

function waitForTimeOrEsc(timeToWait, bAbsoluteTime, startTic)
    errID = 'myException:ESC';
    msg = 'ESC called';
    e = MException(errID,msg);
    if ~exist('bAbsoluteTime','var')
        startTic = GetSecs;
    else fprintf("jonathan\n")
    end
    % repeat until a valid key is pressed or we time out
    timedOut = false;
    while ~timedOut
        % check if a key is pressed
        % only keys specified in activeKeys are considered valid
        [ keyIsDown, keyTime, keyCode ] = KbCheck;
        if keyCode(KbName('ESCAPE')), throw(e)
        elseif((GetSecs - startTic) >= timeToWait), timedOut = true;
        end
    end
end

function waitForMRI()
    t_pressed = false;
    DisableKeysForKbCheck([]);
    fprintf("waiting for next Tr cue from MRI...\n")
    while t_pressed == false
        [keyIsDown,secs, keyCode] = KbCheck;
        if keyCode(KbName('t'))
            t_pressed = true;
            fprintf("got t!\n")
        end
        if keyCode(KbName('ESCAPE'))
            Screen('CloseAll');
            clear all
            return
        end
    end
    DisableKeysForKbCheck(KbName('t'));
end

function [] = waitForSpace()
    spacePressed = 0;
    errID = 'myException:ESC';
    msg = 'ESC called';
    e = MException(errID,msg);
    while ~spacePressed
        % check if a key is pressed
        % only keys specified in activeKeys are considered valid
        [ keyIsDown, keyTime, keyCode ] = KbCheck;
        if keyCode(KbName('SPACE')), spacePressed = 1;
        end
        % if keyCode(KbName('ESCAPE')), throw(e);
        % end
    end
end
