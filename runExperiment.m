close all;
clear all;
sca
clc
pause on



%% constants

%% control which parts of the experiment to run

runWithDisplay = 1;
runFirstPart = 0;
runSecondPart = 1;

numBlocks = 4;
numClassificationBlocks = 4
numCatchTrialBlocks = 2;
numImagesPerBlock = 8;
numImagesPerClassificationBlock = 6;
catchTrialBlockLocations = [2, numBlocks - 1]
catchTrialBlockLocationsClassification = [2, numClassificationBlocks - 1]
% randsample(2:numBlocks-1,numCatchTrialBlocks)

fixationCrossSize = 20; %size of fixation cross in pixels
fixationCoords = [[-fixationCrossSize fixationCrossSize 0 0]; [0 0 -fixationCrossSize fixationCrossSize]];%setting fixation point coordinations
lineWidthFixation = 4; %line width of fixaton cross in pixels
stimSize=[0 0 100 100]; %Set Stimulus Dimantions [top-left-x, top-left-y, bottom-right-x, bottom-right-y].
dispDuration=1;
 % duration of each image display
waitDuration=2;
 % duration to wait betewen blocks
betweenShapesDuration = 0.5; % duration to wait between same-shape displays in a clssification block


%% initiate psychtoolbox
if runWithDisplay
    [window, xCenter, yCenter, black, white] = initScreen();
end

%% load images of shapes
% images = loadImages('/mnt/g/My Drive/Msc neuroscience/lab - mukamel/code/stimuli-presentation-for-fMRI/shape-images/')
images = loadImages('.\shape-images\')

 
 if runFirstPart


     %% run the experiment - part 1
     for i=1:numBlocks
         imageIndices = randperm(numImagesPerBlock); % permute the images
         if ismember(i, catchTrialBlockLocations) % if it's a catch trial - double one of the images
             imageIndices(mod(i, numImagesPerBlock)+1) = imageIndices(mod(i+1, numImagesPerBlock)+1)
         end

         for imgIdx = imageIndices
             % iterate over block images
             img = images{imgIdx};
             Screen('PutImage', window, img); % put image on screen
             Screen('Flip', window);
             WaitSecs(dispDuration);
             
             Screen(window,'FillRect') % clear the screen between shapes
             Screen('Flip', window);
             WaitSecs(betweenShapesDuration);
         end

         Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
         Screen('Flip', window);
         WaitSecs(waitDuration);
         
     end
 end

 if runSecondPart
     %% load confusion matrix
     confusionMatPath = "confusion-matrix-example.csv";
     CM = csvread(confusionMatPath);
     avgCM = 0.5 * (CM + CM'); % consider the meadure of confusion between two shapes as the average of a being confused for B and B for A
     avgCM = avgCM .* ~eye(size(avgCM)); % zero out the diag
     avgCM(avgCM == 0) = NaN; % replace zeros with NaNs
     
     %  get the running index of the max and min confusions
     [v, max_i] = max(avgCM(:));
     [v, min_i] = min(avgCM(:));
     
     % get the proper indices (x,y) from the running index
     [x, y] = ind2sub(size(avgCM), max_i);
     mostConfusedPair = [x, y];
     [x, y] = ind2sub(size(avgCM), min_i);
     leastConfusedPair = [x, y];
     
     %% run the experiment - part 2
     
     indexPairs = [mostConfusedPair; leastConfusedPair];
     % run two cycles of blocks - with the most- and leas-confused pairs
     for p = size(indexPairs,1) 
         indexPair = indexPairs(p,1:size(indexPairs,1));
         blockIndices = [indexPair(1) * ones(1, numClassificationBlocks/2), indexPair(2) * ones(1,numClassificationBlocks/2)]; % every block is either 1 or 2, which is the index of the (single) shape that appears throughout the block.
         blockIndices = blockIndices(randperm(length(blockIndices))); % shuffle the blocks
         for i=1:numClassificationBlocks
             % create the indices to use for displaying the shape(s) in this block
             imageIndices = repmat(blockIndices(i), 1, numImagesPerClassificationBlock);
             if ismember(i, catchTrialBlockLocationsClassification)
                 % if it's a catch trial - change one of the images to the the other shape
                 % since the sum of the indices of the shapes is constant, we get the other  shape by subtracting from the total
                 otherShapeIndex = sum(indexPair) - blockIndices(i);
                 imageIndices(mod(i, numImagesPerClassificationBlock) + 1) = otherShapeIndex;
             end
             
             for imgIdx= imageIndices % iterate over block images
                 img = images{imgIdx};
                 Screen('PutImage', window, img); % put image on screen
                 Screen('Flip', window);
                 WaitSecs(dispDuration);
                 
                 Screen(window,'FillRect') % clear the screen between shapes
                 Screen('Flip', window);
                 WaitSecs(betweenShapesDuration);
                 
                 
             end
             
             Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
             Screen('Flip', window);
             WaitSecs(waitDuration);
             
         end
     end
 end
 
 Screen('CloseAll')
 
 %ShwCursor
 
 
 
 function images = loadImages(dir)
 if ~isfolder(dir)
     errorMessage = sprintf('Error: The following folder does not exist:\n%s', dir);
     uiwait(warndlg(errorMessage));
     return;
 end
 imageDS = imageDatastore(dir,"FileExtensions",[".png"]);
 images = readall(imageDS);
 end
 
 
 
 %Add_Psych;
 %HideCursor;
 function [window, xCenter, yCenter, black, white] = initScreen()
 Screen('Preference', 'VisualDebuglevel', 3); %No PTB intro screen
 Screen('Preference', 'SkipSyncTests', 1); %change to 0 in real experiment
 PsychDefaultSetup(2); % call some default settings for setting up Psychtoolbox
 screens = Screen('Screens');
 screenNumber = max(screens);
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
 
 
 
