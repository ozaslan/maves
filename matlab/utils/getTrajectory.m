function traj = getTrajectory()
%GETTRAJECTORY Returns the trajectory of quadcopter
%   
%   This function returns the trajectory of the quadcopters since the last
%   respawn. Each column consists of stamp and quad. state.
%

global state;

traj = state.qcopter.traj;

