function initialize()
%INITIALIZE This calles all initialization functions
%
%   This function must be called at the very begining of the simulator to
%   initialize all required pameters. There include simulation default
%   parameters, figure and axes for visualizing the arena, and initialize
%   values of the simulator.

initParams();
initArena();
initSim();
initPlots();

