function [stamp, iter] = getStamp()
%GETSTAMP Returns the current simulation time stamp
%   

global state;

stamp = state.sim.stamp;
iter  = state.sim.step;

