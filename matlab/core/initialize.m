function initialize(varargin)
%INITIALIZE This calles all initialization functions
%
%   This function must be called at the very begining of the simulator to
%   initialize all required pameters. There include simulation default
%   parameters, figure and axes for visualizing the arena, and initialize
%   values of the simulator.

parser = inputParser();
parser.addParameter('visualsEnabled', true, ...
    @(value) (islogical(value) || isnumeric(value)) && isscalar(value));
parser.parse(varargin{:});
visualsEnabled = logical(parser.Results.visualsEnabled);

initParams();
global params;
params.sim.visualsEnabled = visualsEnabled;

if params.sim.visualsEnabled
    initArena();
end
initSim();
if params.sim.visualsEnabled
    initPlots();
end
