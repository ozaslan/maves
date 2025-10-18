function [m, I] = getInertia()
%GETINERTIA This returns mass and rotational inertia
%
%   The return values are
%   m : mass in kg.
%   I : rotational inertia in kg m^2

global params;

m = params.qcopter.phys.m;
I = params.qcopter.phys.I;

