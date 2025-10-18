function [pose, stamp] = getPose()
%GETPOSE The returns the pose of the quadcopter and current time stamp 
%   
%   The return values are
%   pose  : a 3-by-1 vector consisting of x, y coordinates and tilt angle
%   stamp : current time stamp
global state;

pose  = state.qcopter.pose(:); 
stamp = getStamp();

