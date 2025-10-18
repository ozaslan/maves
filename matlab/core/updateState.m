function updateState(t, s)
%UPDATESTATE Updates state in simulator database
%   
%   This function updates the state of the quadcopter in simulator
%   database. It also records the trajector of the full quad. state.
%   (note that the trajectory the robot follows is recorded, not the
%   reference trajectory)
%
%   Inputs are t : time stamp
%              s : quad. state vector. This has the same structure as
%              vector returned by 'getStateVector' function.

global state;

assert(isscalar(t));
assert(all(size(s) == [8, 1]));

state.sim.stamp    = t;
state.qcopter.pose = s(1:3); % x, y, th
state.qcopter.vel  = s(4:6); % xdot, ydot, thedot
state.qcopter.w    = s(7:8); % w1, w2
state.qcopter.traj = [state.qcopter.traj, [t; s]];


