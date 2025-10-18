function [s, stamp] = getStateVector()
%GETSTATEVECTOR Returns the state as a column vector
%   
%   This function returns the state of the quadcopter as a column vector.
%   The structure of this vector is a follows
%      s : [x, y, th, xdot, ydot, thdot, w1, w2]'
% 
%   Under 'utils' folder you can find 'getState' function which returns a
%   'pose', 'velocity' and 'w' as separate vectors. You can use which ever
%   flavor fits better to your taste.
global state;

s = [state.qcopter.pose(:); ...
     state.qcopter.vel(:); ...
     state.qcopter.w(:)];
 
stamp = getStamp();


