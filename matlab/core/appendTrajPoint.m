function appendTrajPoint(t, sT)
%APPENDTRAJPOINT Expand the traj. history with t and sT
%   
%   This function adds the reference trajectory point into the simulator 
%   database for later plotting and performance assessment (note that this
%   records reference trajectory, not the trajectory that is actually
%   followed by the quad.)
%
%   Inputs are t  : time stamp
%              sT : trajectory point consisting pose, velocity and 
%                   acceleration. This is a 9-by-1 vector.
global state;

assert(isscalar(t));
assert(all(size(sT) == [9, 1]));

state.qcopter.trajHist = [state.qcopter.trajHist, [t ; sT]];

