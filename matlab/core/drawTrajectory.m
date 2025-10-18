function drawTrajectory()
% DRAWTRAJECTORY   This function draws trajectory of quadcopter
%
%   This function draws on the arena the past positions of the quadcopter
%   since the last respawn.

global state;
global params;

h      = params.arena.axesHandle;
tColor = params.qcopter.visual.trajColor;
cColor = params.qcopter.visual.commandsColor;

xs = state.qcopter.traj(2, :);
ys = state.qcopter.traj(3, :);

plot(h, xs, ys, tColor, 'LineWidth', 2);

xs = state.qcopter.trajHist(2, :);
ys = state.qcopter.trajHist(3, :);

plot(h, xs, ys, cColor);



    