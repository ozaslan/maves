function sT = evalTrajectory(t, s)
%EVALTRAJECTORY This calls the trajectory generator function registered by
%               user
%
%   This function retrieves the handle to the trajectory generator function 
%   provided by the user through 'setTrajectoryGenerator()' and relays its 
%   output.

global params;

hTraj = params.trajGen;
sT    = hTraj(t, s);

