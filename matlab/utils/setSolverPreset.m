function setSolverPreset(preset, method)
%SETSOLVERPRESET Configure ODE solver parameters using named presets.
%   setSolverPreset('balanced') sets a default solver configuration.
%   setSolverPreset('fast', 'ode23') selects a preset and solver method.

arguments
    preset (1, :) char = 'balanced'
    method (1, :) char = ''
end

global params;
global state;

validPresets = {'fast', 'balanced', 'accurate'};
validMethods = {'ode45', 'ode23'};

preset = validatestring(preset, validPresets, mfilename, 'preset');
if ~isempty(method)
    method = validatestring(method, validMethods, mfilename, 'method');
end

solverCfg = struct('preset', preset, ...
    'method', 'ode45', ...
    'timeStep', 1 / params.sim.freq, ...
    'relTol', 1e-5, ...
    'absTol', 1e-6);

switch preset
    case 'fast'
        solverCfg.timeStep = 1 / 25;
        solverCfg.relTol = 1e-3;
        solverCfg.absTol = 1e-5;
    case 'balanced'
        solverCfg.timeStep = 1 / 50;
        solverCfg.relTol = 1e-5;
        solverCfg.absTol = 1e-6;
    case 'accurate'
        solverCfg.timeStep = 1 / 100;
        solverCfg.relTol = 1e-7;
        solverCfg.absTol = 1e-8;
end

if isempty(method)
    method = solverCfg.method;
end
solverCfg.method = method;

params.sim.solver = solverCfg;
params.sim.freq = 1 / solverCfg.timeStep;

if isfield(state, 'sim')
    state.sim.solver = solverCfg;
    state.sim.solverHandle = str2func(solverCfg.method);
    state.sim.solverOptions = odeset('RelTol', solverCfg.relTol, ...
        'AbsTol', solverCfg.absTol, 'Stats', 'off');
end
