function setTrajectoryGenerator(h, varargin)
%SETTRAJECTORYGENERATOR Use this function to set traj. generator
%   
%   The input must be a handle to a trajectory generator function.
%   The input - output specifications of a generator function are given in
%   template functions. See 'trajHover', 'trajLine', 'trajDiamond',
%   'trajCircle'.

global params;

h = @(t, s) h(t, s, varargin{:});
params.trajGen = h;

