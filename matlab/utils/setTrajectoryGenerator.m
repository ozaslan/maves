function setTrajectoryGenerator(h, varargin)
%SETTRAJECTORYGENERATOR Use this function to set traj. generator
%
%   The input must be a handle to a trajectory generator function.
%   The input - output specifications of a generator function are given in
%   template functions. See 'trajHover', 'trajLine', 'trajDiamond',
%   'trajCircle'.

global params;

if isempty(varargin)
    trajArgs = {};
elseif numel(varargin) == 1
    candidate = varargin{1};
    if isstruct(candidate)
        trajArgs = struct2cell(candidate);
    elseif iscell(candidate)
        trajArgs = candidate;
    else
        trajArgs = {candidate};
    end
else
    trajArgs = varargin;
end

h = @(t, s) h(t, s, trajArgs{:});
params.trajGen = h;

