function [pose, vel, w, stamp] = getState()
%GETSTATE Returns the components of state separately
%   
%   This function returns the state of the quadcopter in 3 parts. The
%   return values are 'pose', 'velocity', 'w' and 'stamp'. Non-scalar
%   return values are column vectors.
% 
%   Under 'utils' folder you can find 'getStateVector' function which 
%   returns 'pose', 'velocity' and 'w' stacked into a single column vector.
%   You can use which ever flavor fits better to your taste.
global state;

pose  = state.qcopter.pose(:);
vel   = state.qcopter.vel(:);
w     = state.qcopter.w(:);
stamp = getStamp();

