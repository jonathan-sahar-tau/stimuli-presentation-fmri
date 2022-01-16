close all;
clear all;
sca
clc
pause on



%% constants
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
interBlockDuration = 1; % duration to wait between same-shape displays in a clssification block

% 
% %% initiate psychtoolbox
%  [window, xCenter, yCenter, black, white] = initScreen();
% 
% %% load images of shapes
% % images = loadImages('/mnt/g/My Drive/Msc neuroscience/lab - mukamel/code/stimuli-presentation-for-fMRI/shape-images/')
% images = loadImages('G:\My Drive\Msc neuroscience\lab - mukamel\code\stimuli-presentation-for-fMRI\shape-images\')
% 
% 
% %% run the experiment - part 1
% for i=1:numBlocks
%     imageIndices = randperm(numImagesPerBlock); % permute the images
%     if ismember(i, catchTrialBlockLocations) % if it's a catch trial - double one of the images
%         imageIndices(mod(i, numImagesPerBlock)+1) = imageIndices(mod(i+1, numImagesPerBlock)+1)
%     end
% 
%     for imgIdx = imageIndices
%  % iterate over block images
%     img = images{imgIdx};
%     Screen('PutImage', window, img); % put image on screen
%     Screen('Flip', window);
%     WaitSecs(dispDuration);
%     end
% 
%     Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
%     Screen('Flip', window);
%     WaitSecs(waitDuration);
%    
% end

%% initiate psychtoolbox
 [window, xCenter, yCenter, black, white] = initScreen();

%% load images of shapes
% images = loadImages('/mnt/g/My Drive/Msc neuroscience/lab - mukamel/code/stimuli-presentation-for-fMRI/shape-images/classification-task')
images = loadImages('G:\My Drive\Msc neuroscience\lab - mukamel\code\stimuli-presentation-for-fMRI\shape-images\classification-task')

 %% run the experiment - part 2
blockIndices = [ones(1, numClassificationBlocks/2), 2 * ones(1,numClassificationBlocks/2)]; % every block is either 1 or 2, which is the index of the (single) shape that appears throughout the block.
blockIndices = blockIndices(randperm(length(blockIndices))); % shuffle the blocks
for i=1:numClassificationBlocks
    imageIndices = repmat(blockIndices(i), 1, numImagesPerClassificationBlock); % create the indices to use for displaying the shape(s) in this block
    if ismember(i, catchTrialBlockLocationsClassification) % if it's a catch trial - change one of the images to the the other shape
        imageIndices(mod(i, numImagesPerClassificationBlock) + 1) = 3 - imageIndices(i); % since the indices of the shapes are always 1 or 2, we get the other shape by subtracting from 3
    end

    for imgIdx= imageIndices % iterate over block images
    img = images{imgIdx};
    Screen('PutImage', window, img); % put image on screen
    Screen('Flip', window);
    WaitSecs(dispDuration);
    Screen(window,'FillRect')
    % Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter
                                                                           % yCenter], 2);
    Screen('Flip', window);
    WaitSecs(interBlockDuration);
   
    
    end

    Screen('DrawLines', window, fixationCoords, lineWidthFixation, black, [xCenter yCenter], 2);
    Screen('Flip', window);
    WaitSecs(waitDuration);
   
end


Screen('CloseAll')

%ShwCursor



function images = loadImages(dir)
    myFolder = '/mnt/g/My Drive/Msc neuroscience/lab - mukamel/code/stimuli-presentation-for-fMRI/shape-images/classification-task';
    % myFolder = 'G:\My Drive\Msc neuroscience\lab - mukamel\code\stimuli-presentation-for-fMRI\shape-images\classification-task';
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
