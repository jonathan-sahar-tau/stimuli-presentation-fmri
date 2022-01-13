close all;
clear all;
% sca
clc
pause on
%% get participant data
%% initiate psychtoolbox
%Add_Psych;
HideCursor;
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
%%
%% constant variables
% experiment length
runNum=0
DispTime=0.8;
instTime=1;
eventTime=1.5;
eventsPerBlock=6;
numRuns=6;
timeBetweenBlocks=7.5;
if runNum==0
    blocksPerRun=2;
else
    blocksPerRun=16;
end
% display parsameters
fixationCrossSize = 10; %size of fixation cross in pixels
fixationCoords = [[-fixationCrossSize fixationCrossSize 0 0]; [0 0 -fixationCrossSize fixationCrossSize]];%setting fixation point coordinations
lineWidthFixation = 2; %line width of fixaton cross in pixels
stimSize=[0 0 100 100]; %Set Stimulus Dimantions [top-left-x, top-left-y, bottom-right-x, bottom-right-y].
RightX=0.7; %location on the right visual field
blockType={'rightHand.png','leftHand.png'};
escape=0;
%%
%% load parameters
%% get que from MRI
if runNum~=0
DrawFormattedText(window, ...
    [ 'Scan number ', num2str(runNum), ' out of ', num2str(numRuns), ' is about to start.'], 'center', 'center', white);
Screen('Flip', window);
t_pressed = false;
DisableKeysForKbCheck([]);
while t_pressed == false
    [keyIsDown,secs, keyCode] = KbCheck;
    if keyCode(t)
        t_pressed = true;
    end
    if keyCode(esc)
        Screen('CloseAll');
        clear all
        return
    end
end
DisableKeysForKbCheck(t);
else
    runNum=1;
end
%%
%% start experiment
stimPosition=CenterRectOnPointd(stimSize, xCenter, yCenter);
startRun=tic;
for j=1:blocksPerRun
    if escape
        break
    end
    ima=imread(blockType{trialOrder(j*eventsPerBlock,runNum,2)+1}, 'PNG');
    ima=double(logical(ima));
    Screen('PutImage', window, ima); % put image on screen
    Screen('Flip', window);
    WaitSecs(instTime-0.3);
    Screen('DrawLines', window, fixationCoords, lineWidthFixation, white, [xCenter yCenter], 2);
    Screen('Flip', window);
    WaitSecs(0.3);
    for i=1:eventsPerBlock
        if trialOrder((j*eventsPerBlock-eventsPerBlock+i),runNum,1)
            stimColor=catchColor;
        else
            stimColor=stimRealColor;
        end
        Screen('DrawLines', window, fixationCoords, lineWidthFixation, green, [xCenter yCenter], 2);
        Screen('Flip', window);
        pressed=0;
        tic;
        while ~pressed
            [keyIsDown ,sec, keyCode] = KbCheck;
            if (keyCode(l)&&trialOrder(j*eventsPerBlock-eventsPerBlock+i,runNum,2)==0)||...
                    (keyCode(a)&&trialOrder(j*eventsPerBlock-eventsPerBlock+i,runNum,2)==1)
                RT(i,j)=toc;
                pressed=1;
                if all(stimColor==catchColor)
                    countCatch=countCatch+1;
                end
            elseif (keyCode(a)&&trialOrder(j*eventsPerBlock-eventsPerBlock+i,runNum,2)==0)||...
                    (keyCode(l)&&trialOrder(j*eventsPerBlock-eventsPerBlock+i,runNum,2)==1)
                falsePress(i,j)=toc;
                RT(i,j)=nan;
                Screen('TextSize', window, 90);
                DrawFormattedText(window, 'X' ,'center', 'center', [1,0,0]);
                Screen('Flip', window);
                WaitSecs(0.3);
                time=falsePress(i,j);
                pressed=1;
                Screen('TextSize', window, 30);
            elseif keyCode(esc)
                escape=1;
                break
            elseif toc>0.7
                Screen('TextSize', window, 90);
                DrawFormattedText(window, 'X' ,'center', 'center', [1,0,0]);
                Screen('Flip', window);
                WaitSecs(0.3);
                pressed=1;
                RT(i,j)=nan;
                time=toc;
                Screen('TextSize', window, 30);
            end
        end
        if escape
            break
        elseif isnan(RT(i,j))
            Screen('DrawLines', window, fixationCoords, lineWidthFixation, white, [xCenter yCenter], 2);
            Screen('Flip', window);
            WaitSecs(eventTime-time);
        else
            Screen('DrawLines', window, fixationCoords, lineWidthFixation, white , [xCenter yCenter], 2);
            Screen('FillOval', window, stimColor, stimPosition);
            Screen('Flip', window);
            WaitSecs(DispTime);
            Screen('DrawLines', window, fixationCoords, lineWidthFixation, white, [xCenter yCenter], 2);
            Screen('Flip', window);
            WaitSecs(eventTime-RT(i)-DispTime);
        end
    end
    if escape
        break
    else
          pause(timeBetweenBlocks);
    end
end
%%
%%catch count display
if ~escape
    ima=imread(howMany, 'PNG');
    ima=double(logical(ima));
    Screen('PutImage', window, ima); % put image on screen
    Screen('Flip', window);
    KbWait;
    DrawFormattedText(window, num2str(countCatch) ,'center', 'center', white);
    Screen('Flip', window);
    KbWait;
    [keyIsDown,secs, keyCode] = KbCheck;
    countedCatch=keyCode;
end
%% save variables
if runNum~=0
    save([direc,'\',subject,'Run',num2str(runNum)]);
end
%%
%% close psychtoolbox
endTime=toc(startRun);
KbWait;
ShowCursor;
sca
%Remove_Psych;
