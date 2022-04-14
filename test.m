tstart = GetSecs
waitForTimeOrEsc(3)
fprintf("Done!\n")


function waitForTimeOrEsc(timeToWait, bAbsoluteTime, startTic)
    errID = 'myException:ESC';
    msg = 'ESC called';
    e = MException(errID,msg);
    if ~exist('bAbsoluteTime','var')
        startTic = GetSecs
    end
    % repeat until a valid key is pressed or we time out
    timedOut = false;
    while ~timedOut
        if((GetSecs - startTic) >= timeToWait), timedOut = true; end
        % check if a key is pressed
        % only keys specified in activeKeys are considered valid
        [ keyIsDown, keyTime, keyCode ] = KbCheck;
        if keyCode(KbName('ESCAPE')), throw(e)
        end
    end
end
