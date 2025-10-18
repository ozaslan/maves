function updateAxesTitle()
%UPDATEAXESTITLE This updates the arena axes title
%
%   This function updates the arena axes title with a number of useful
%   information such as current time stamp, pose and velocity of the
%   quadcopter.

global params;

h = params.arena.axesHandle;

stamp = getStamp();
[pose, vel] = getState();

tStr = ['t = ' num2str(stamp, '%.2f') ' secs.'];
rStr = ['r = [' ...
        num2str(pose(1), '%.3f') ', ' ...
        num2str(pose(2), '%.3f') ', ' ...
        num2str(pose(3), '%.3f') ']'];
vStr = ['$\dot{r}$ = [' ...
        num2str(vel(1), '%.3f') ', ' ...
        num2str(vel(2), '%.3f') ', ' ...
        num2str(vel(3), '%.3f') ']'];

titleText = [tStr ', ' rStr ', ' vStr];
title(h, titleText, 'interpreter', 'latex');

