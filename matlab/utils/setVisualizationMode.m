function setVisualizationMode(mode)
%SETVISUALIZATIONMODE Configure how simulator plots are updated.
%
%   setVisualizationMode('live')     - Update arena and telemetry plots at
%                                      every simulation step (default).
%   setVisualizationMode('deferred') - Skip intermediate drawing and only
%                                      render the final state when the
%                                      simulation completes.
%   setVisualizationMode('off')      - Disable visualization entirely.

global params;

if nargin < 1 || isempty(mode)
    mode = 'live';
end

if isstring(mode)
    if ~isscalar(mode)
        error('Visualization mode must be a single string or character vector.');
    end
    mode = char(mode);
end

validModes = {'live', 'deferred', 'off'};
mode = validatestring(mode, validModes, mfilename, 'mode');

if ~isfield(params, 'sim') || isempty(params.sim)
    params.sim = struct();
end

if ~isfield(params.sim, 'visualsEnabled') || isempty(params.sim.visualsEnabled)
    params.sim.visualsEnabled = true;
end

if strcmpi(mode, 'off')
    params.sim.visualsEnabled = false;
end

params.sim.runMode = mode;
