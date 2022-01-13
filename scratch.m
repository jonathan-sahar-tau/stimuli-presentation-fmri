
close all;
clear all;
sca
clc
pause on
%% initiate psychtoolbox
%Add_Psych;
%HideCursor;
%ShowCursor
Screen('Preference', 'VisualDebuglevel', 3); %No PTB intro screen
Screen('Preference', 'SkipSyncTests', 1); %change to 0 in real experiment
PsychDefaultSetup(2); % call some default settings for setting up Psychtoolbox
screens = Screen('Screens');
screenNumber = max(screens); 
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
green=[0,1,0];
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
[screenXpixels, screenYpixels] = Screen('WindowSize', window); %get the size of the scrren in pixel
[xCenter, yCenter] = RectCenter(windowRect); % Get the centre coordinate of the window in pixels
% text preferences
Screen('TextSize', window, 30);


%% constants
DispTime=0.8;
instTime=1;
numBlocks = 10;
numCatchTrialBlocks = 2;
numImagesPerBlock = 8;
catchTrialBlockLocations = randsample(2:numBlocks-1,numCatchTrialBlocks)

%% load images of shapes
% myFolder = '/mnt/g/My Drive/Msc neuroscience/lab - mukamel/code/stimuli-presentation-for-fMRI/shapeimages';
myFolder = 'G:\My Drive\Msc neuroscience\lab - mukamel\code\stimuli-presentation-for-fMRI\shapeimages';

if ~isfolder(myFolder)
  errorMessage = sprintf('Error: The following folder does not exist:\n%s', myFolder);
  uiwait(warndlg(errorMessage));
  return;
end

imageDatastore = imageDatastore(myFolder,"FileExtensions",[".png"]);
images = readall(imageDatastore);



%% run the experiment

for i=1:numBlocks
    imageIndices = randperm(numImagesPerBlock); %% permute the images
    if ismember(i, catchTrialBlockLocations) %% if it's a catch trial - double one of the images
        imageIndices(mod(i, numImagesPerBlock)+1) = imageIndices(mod(i+1, numImagesPerBlock)+1)
    end


    %% display images
    for imageIdx=1:length(imageIndices)
    img = readimage(imageDatastore, imageIdx);
    Screen('PutImage', window, img); % put image on screen
    Screen('Flip', window);
    WaitSecs(instTime-0.3);
    Screen('DrawLines', window, FixationCoords, lineWidthFixation, white, [xCenter yCenter], 2);
    Screen('Flip', window);
    WaitSecs(0.3);
    end
    
end
