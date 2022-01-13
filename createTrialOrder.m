function trailOrder=createTrialOrder(order, numRuns, blocksPerRun, eventsPerBlock)
% This function gets the order of the experiment
% 1= RIGHT VISUAL FIELD FIRST
% 2= LEFT VISUAL FIELD FIRST
% This function gets the color of the catch stimulus
% This function returns the order of trails for a specific subject
% col- specific run
% first dim- stim color
% second dim- oprating hand (0 right 1 left)
% third dim- stim location (0 right 1 left)
trailOrder=nan(blocksPerRun*eventsPerBlock,numRuns,3);
countCatch=[4,2,2,2,4,2];
for runn=1:numRuns
    handOrder=Shuffle([zeros(1,blocksPerRun/2),ones(1,blocksPerRun/2)]);
    bcatch=[0,Shuffle([zeros(1,blocksPerRun-countCatch(runn)-1),ones(1,countCatch(runn))])];
    while sum(handOrder(bcatch==1))~=countCatch(runn)/2
            bcatch=[0,Shuffle([zeros(1,blocksPerRun-countCatch(runn)-1),ones(1,countCatch(runn))])];
    end
    for block=1:blocksPerRun
        if ~bcatch(block)
            trailOrder(block*eventsPerBlock-eventsPerBlock+1:block*eventsPerBlock,runn,1)=0;
        else
            trailOrder(block*eventsPerBlock-eventsPerBlock+1:block*eventsPerBlock,runn,1)=Shuffle([zeros(1,eventsPerBlock-1),1]);            
        end    
        trailOrder(block*eventsPerBlock-eventsPerBlock+1:block*eventsPerBlock,runn,2)=handOrder(block);
        trailOrder(:,runn,3)=double((order==2&runn<=numRuns/2)||(order==1&runn>(numRuns/2)));
    end
end