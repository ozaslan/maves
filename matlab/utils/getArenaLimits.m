function L = getArenaLimits()
%GETARENALIMITS Returns the arena limits
%
%   This function returns the limits of the arena in a 2-by-2 matrix where
%   the first column is the bottom-left x-y coordinate and the second
%   column is the top-right x-y coordinates of the arena.

global params;

L = params.arena.limits;