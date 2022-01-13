function [subject, runNum, order, eyetracker]=backgroundData
prompt = {'Subject:','Run:','Order:','Use eyetracker?'};
dlg_title = 'Suject Data';
num_lines = 1;
def = {'','0- train real 1-6','1,2','0,1'};
answer = inputdlg(prompt,dlg_title,num_lines,def);
subject=(answer{1});
runNum=str2num(answer{2});
order=str2num(answer{3});
eyetracker=str2num(answer{4});
ok=0;
while ~ok
ok=1;
def={answer{1},answer{2},answer{3},answer{4}};
    direc=fullfile('.','dataFiles',subject);
if exist([direc,'\',subject,'Run',num2str(runNum),'.mat'])
    prompt{1}='Subject and run number already exsits, enter a different value:';
    ok=0;
end
if order<1 || order>2
    prompt{3}='Invalid order. order must be between 1 or 2';
    ok=0;
end
if runNum<0 || runNum>6
    prompt{2}='Invalid run';
    ok=0;
end
if ~ok
answer= inputdlg(prompt,dlg_title,num_lines,def);
subject=answer{1};
runNum=str2num(answer{2});
order=str2num(answer{3});
eyetracker=str2num(answer{4});
end
end