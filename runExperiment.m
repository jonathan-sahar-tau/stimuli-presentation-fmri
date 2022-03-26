close all;
clear all;
sca
clc
pause on
addpath('../utils');
rng(0,'twister');

%% constants

%% control which parts of the experiment to run

runWithDisplay = 1;
runFirstPart = 0;
runSecondPart = 1;

numRuns = 2;
numBlocks = 4;
numImagesPerBlock = 4;
numCatchTrialBlocks = 2;
catchTrialBlockLocations = [randi([1, numBlocks/2], 1), randi([numBlocks/2 + 1, numBlocks], 1)]
blocks = [[1 3 5 7]; [2 4 6 8]] % two typse of 4-image blocks for first part
% duration of each image display
dispDuration= 1;
% duration to wait between shape displays in a block
betweenShapesDuration = 0.5;
% duration to wait betewen blocks
blockWaitDuration=8;


numRuns_classification = 4;
numBlocks_classification = 6;
assert(mod(numBlocks_classification, 3) == 0);
numImagesPerClassificationBlock = 6;
catchTrialBlockLocations_classification = [randi([1, numBlocks_classification/2], 1),...
    randi([numBlocks_classification/2 + 1, numBlocks_classification], 1)]
% randsample(2:numBlocks-1,numCatchTrialBlocks)

fixationCrossSize = 20; %size of fixation cross in pixels
fixationCoords = [[-fixationCrossSize fixationCrossSize 0 0]; [0 0 -fixationCrossSize fixationCrossSize]];%setting fixation point coordinations
lineWidthFixation = 4; %line width of fixaton cross in pixels
stimSize=[0 0 100 100]; %Set Stimulus Dimantions [top-left-x, top-left-y, bottom-right-x, bottom-right-y].
% duration of each image display
dispDuration_classification= 0.75;
% duration to wait between same-shape displays in a clssification block
betweenShapesDuration_classification = 0.25;
% duration to wait betewen blocks
blockWaitDuration_classification=8;


%% initiate psychtoolbox
if runWithDisplay
    [window, xCenter, yCenter, black, white] = initScreen();
end


KbName('UnifyKeyNames');
% specify key names of interest
activeKeys = [KbName('ESCAPE') KbName('t')];
% activeKeys = [KbName('LeftArrow') KbName('RightArrow')];
% restrict the keys for keyboard input to the keys we want
% RestrictKeysForKbCheck(activeKeys);
% suppress echo to the command line for keypresses
% ListenChar(2);

%% load images of shapes
% images = loadImages('/mnt/g/My Drive/Msc neuroscience/lab - mukamel/code/stimuli-presentation-for-fMRI/shape-images/')
images = loadImages('.\shape-images\centered\')




%% which subject are we running? keep its stats
load('./subjectData/latestSubjectId.mat')
subjectId = subjectId + 1;
save ./subjectData/latestSubjectId.mat subjectId;

logFile = "log_" + subjectId + ".mat"
runLog = {};
runLogClassification = {};


blockStartTimes = [];
blockStartTimes_classification = [];
blockEndTimes = [];
blockEndTimes_classification = [];

imageStartTimes = [];
imageStartTimes_classification = [];
imageEndTimes = [];
imageEndTimes_classification = [];


imageIndex = [];
imageIndex_classification = [];

catchTrialIndex = zeros(1, numBlocks);
catchTrialIndex(1,catchTrialBlockLocations) = 1;

catchTrialIndex_classification = zeros(1, numBlocks_classification);
catchTrialIndex_classification(1,catchTrialBlockLocations_classification) = 1;


if runFirstPart
    
    %% run the experiment - part 1
    try
    for run = 1:numRuns
        waitForMRI();
        startTic = tic;
        
        % start each run with a rest period
        Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
        
        Screen('Flip', window);
        waitForTimeOrEsc(blockWaitDuration_classification);
        
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
            blockStartTimes(1,end+1)= toc(startTic);
            
            for imgIdx = imageIndices
                % iterate over block images
                img = images{imgIdx};
                Screen('PutImage', window, img); % put image on screen
                Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
                
                imageStartTimes(1,end+1)= toc(startTic);
                Screen('Flip', window);
                
                waitForTimeOrEsc(dispDuration);
                
                Screen(window,'FillRect') % clear the screen between shapes
                Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
                
                Screen('Flip', window);
                imageEndTimes(1,end+1)= toc(startTic);
                
                waitForTimeOrEsc(betweenShapesDuration);
                
            end % images in block
            % log the end of this block:
            blockEndTimes(1,end+1)= toc(startTic)
            
            Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
            Screen('Flip', window);
            waitForTimeOrEsc(blockWaitDuration);
            fprintf('finished block %d', i);
        end % blocks in run
        fprintf('finished run %d', run);
        runLog{run}.blockStartTimes = blockStartTimes;
        runLog{run}.blockEndTimes = blockEndTimes;
        runLog{run}.catchTrialIndex = catchTrialIndex;
        
    end % runs
        catch exp % catch an ESC meant to stop the script
%             rethrow(exp)
        end
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
        
        for run = 1:numRuns_classification
%             DrawFormattedText(window, [ 'Scan number ', num2str(run), ' out of ', num2str(numRuns), ' is about to start.'])
             % , 'center', 'center', whitte);
%             Screen('Flip', window);
            
            waitForMRI();
            startTic = tic;
            % start each run with a rest period
            Screen('DrawLines', window, fixationCoords, lineWidthFixation, ...
                black, [xCenter yCenter], 2);
            Screen('Flip', window);
            waitForTimeOrEsc(blockWaitDuration_classification);
            
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
                blockIndices = [indexPair(1) * ones(1, numBlocks_classification/3),...
                                indexPair(2) * ones(1,numBlocks_classification*2/3)];
                
                blockIndices = blockIndices(randperm(length(blockIndices))); % shuffle the blocks
                for i=1:numBlocks_classification
                    % create the indices to use for displaying the shape(s)
                    % in this block
                    imageIndices = repmat(blockIndices(i), 1, numImagesPerClassificationBlock);
                    if ismember(i, catchTrialBlockLocations_classification)
                        % if it's a catch trial - change one of the images
                        % to the the other shape since the sum of the
                        % indices of the shapes is constant, we get the other
                        % shape by subtracting from the total
                        otherShapeIndex = sum(indexPair) - blockIndices(i);
                        catchImageIndex = randi([2,numImagesPerClassificationBlock], 1);
                        imageIndices(catchImageIndex) = otherShapeIndex;
                    end
                    
                    imageIndex_classification = [imageIndex_classification imageIndices];
                    
                    % log the start of this block
                    blockStartTimes_classification(1, end+1) = toc(startTic);
                    for imgIdx = imageIndices % iterate over block images
                        img = images{imgIdx};
                        Screen('PutImage', window, img); % put image on screen
                        Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
                        
                        Screen('Flip', window);
                        imageStartTimes_classification(1,end+1)= toc(startTic);
                        
                        waitForTimeOrEsc(dispDuration_classification);
                        
                        Screen(window,'FillRect') % clear the screen between shapes
                        Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
                        Screen('Flip', window);
                        imageEndTimes_classification(1,end+1)= toc(startTic);
                        
                        waitForTimeOrEsc(betweenShapesDuration_classification);
                        
                    end % images in block
                    
                    % log the end of this block
                    blockEndTimes_classification(1, end+1) = toc(startTic);
                    Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
                    Screen('Flip', window);
                    waitForTimeOrEsc(blockWaitDuration_classification);
                    
                end % blocks in image pair
            end % image pairs in run
            
            runLogClassification{run}.blockStartTimes_classification= blockStartTimes_classification;
            runLogClassification{run}.blockEndTimes_classification= blockEndTimes_classification;
            runLogClassification{run}.imageIndex_classification= imageIndex_classification;
        end % runs
    catch exp % catch an ESC meant to stop the script
    rethrow(exp)
    end
end % if second part
%     log{2} = runLog;

Screen('CloseAll')
ShowCursor
save (logFile, 'runLog', 'runLogClassification')

%     RestrictKeysForKbCheck([]);
DisableKeysForKbCheck([]);

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
screenNumber = max(screens) - 1;
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

function waitForTimeOrEsc(timeToWait)
errID = 'myException:ESC';
msg = 'ESC called';
e = MException(errID,msg);
tStart = GetSecs;
% repeat until a valid key is pressed or we time out
timedOut = false;
while ~timedOut
    % check if a key is pressed
    % only keys specified in activeKeys are considered valid
    [ keyIsDown, keyTime, keyCode ] = KbCheck;
    if keyCode(KbName('ESCAPE')), throw(e)
    elseif((keyTime - tStart) >= timeToWait), timedOut = true;
    end
end
end

    function waitForMRI()
    t_pressed = false;
    DisableKeysForKbCheck([]);
    fprintf("waiting for next Tr cue from MRI...")
    while t_pressed == false
        [keyIsDown,secs, keyCode] = KbCheck;
        if keyCode(KbName('t'))
            t_pressed = true;
            fprintf("got t\n")
        end
        if keyCode(KbName('ESCAPE'))
            Screen('CloseAll');
            clear all
            return
        end
    end
    DisableKeysForKbCheck(KbName('t'));
    end
