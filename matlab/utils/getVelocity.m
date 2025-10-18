function [vel, stamp] = getVelocity()
%GETVELOCITY returns velocity of quadcopter
%   
%   The return values are 'vel', a 3-by-1 vector consisting of xdot, ydot 
%   and thdot, and 'stamp' current time stamp.

global state;

vel = state.qcopter.vel(:); 
stamp = getStamp();



