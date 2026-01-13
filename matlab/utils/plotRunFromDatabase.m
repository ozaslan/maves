function [runData, metrics] = plotRunFromDatabase(databaseFile, opts)
%PLOTRUNFROMDATABASE Recreate runsim plots using stored database data.
%   [RUNDATA, METRICS] = PLOTRUNFROMDATABASE(DATABASEFILE) loads a scenario
%   run from the database saved by run_all_scenarios.m, restores the
%   simulator state, and generates the same plots/metrics as runsim without
%   re-simulating.
%
%   [...] = PLOTRUNFROMDATABASE(..., 'scenarioName', 'line-default',
%   'controllerType', 'lqr', 'controllerProfile', 'default') selects a run
%   that matches the same parameter set used by runsim.
%
%   Optional name/value pairs:
%     runIndex           - Explicit index into the database runs array.
%     solverPreset       - Solver preset name (fast, balanced, accurate).
%     showPlots          - Toggle the summarizeRun plots.
%     showTable          - Toggle the summarizeRun table.
%     showArena          - Toggle the arena/trajectory plot.
%     showTelemetry      - Toggle the time-history telemetry plots.
%     visualsEnabled     - Enable/disable figure creation.
%     runPsdReport       - Toggle the PSD report.

arguments
    databaseFile (1, :) char = ''
    opts.scenarioName (1, :) char = ''
    opts.controllerType (1, :) char = ''
    opts.controllerProfile (1, :) char = ''
    opts.solverPreset (1, :) char = ''
    opts.runIndex (1, 1) double = NaN
    opts.showPlots (1, 1) logical = true
    opts.showTable (1, 1) logical = true
    opts.showArena (1, 1) logical = true
    opts.showTelemetry (1, 1) logical = true
    opts.visualsEnabled (1, 1) logical = true
    opts.runPsdReport (1, 1) logical = true
end

if isempty(databaseFile)
    rootDir = getRootFolder();
    databaseFile = fullfile(rootDir, 'database', 'scenario_runs.mat');
end

if ~exist(databaseFile, 'file')
    error('Database file not found: %s', databaseFile);
end

loaded = load(databaseFile, 'database');
if ~isfield(loaded, 'database')
    error('Database file does not contain a ''database'' struct: %s', databaseFile);
end

database = loaded.database;
if ~isfield(database, 'runs') || isempty(database.runs)
    error('Scenario database is empty: %s', databaseFile);
end

runData = selectRun(database.runs, opts);

initialize('visualsEnabled', opts.visualsEnabled);

global state;
global params;

if isfield(runData, 'scenario') && ~isempty(runData.scenario)
    setScenario(runData.scenario);
    if isfield(runData.scenario, 'controllerParams')
        params.controllerParams = runData.scenario.controllerParams;
    end
    if isfield(runData.scenario, 'visualizationMode')
        setVisualizationMode(runData.scenario.visualizationMode);
    end
    if isfield(runData.scenario, 'captureMode')
        setCaptureMode(runData.scenario.captureMode);
    end
end

if isfield(runData, 'sim') && ~isempty(runData.sim)
    state.sim = runData.sim;
    if isfield(runData.sim, 'solver')
        params.sim.solver = runData.sim.solver;
        if isfield(runData.sim.solver, 'timeStep') && runData.sim.solver.timeStep > 0
            params.sim.freq = 1 / runData.sim.solver.timeStep;
        end
    end
end

if isfield(runData, 'log') && ~isempty(runData.log)
    state.qcopter = runData.log;
end

if isfield(params, 'qcopter') && isfield(params.qcopter, 'visual')
    params.qcopter.visual.plotTraj = opts.showArena;
    if ~opts.showTelemetry
        params.qcopter.visual.plotFreq = 0;
    end
end

if opts.visualsEnabled && (opts.showArena || opts.showTelemetry)
    initPlots();
    updateVisuals(true);
end

metrics = summarizeRun('showPlots', opts.showPlots, 'showTable', opts.showTable);

if opts.runPsdReport
    runPsdReport();
end

end

function runData = selectRun(runs, opts)
runCount = numel(runs);

if ~isnan(opts.runIndex)
    if opts.runIndex < 1 || opts.runIndex > runCount
        error('runIndex must be between 1 and %d.', runCount);
    end
    runData = runs(opts.runIndex);
    return;
end

matches = true(1, runCount);
if ~isempty(opts.scenarioName)
    matches = matches & matchField(runs, 'name', opts.scenarioName, 'scenario');
end
if ~isempty(opts.controllerType)
    matches = matches & matchField(runs, 'controllerType', opts.controllerType, 'scenario');
end
if ~isempty(opts.controllerProfile)
    matches = matches & matchField(runs, 'controllerProfile', opts.controllerProfile, 'scenario');
end
if ~isempty(opts.solverPreset)
    matches = matches & matchSolverPreset(runs, opts.solverPreset);
end

indices = find(matches);
if isempty(indices)
    error('No database runs matched the requested parameters.');
end
if numel(indices) > 1
    error('Multiple database runs matched the requested parameters. Use runIndex to disambiguate.');
end

runData = runs(indices);
end

function matches = matchField(runs, fieldName, value, structName)
runCount = numel(runs);
matches = false(1, runCount);

for idx = 1:runCount
    run = runs(idx);
    if ~isfield(run, structName) || ~isfield(run.(structName), fieldName)
        continue;
    end
    currentValue = run.(structName).(fieldName);
    if isstring(currentValue) || ischar(currentValue)
        matches(idx) = strcmpi(string(currentValue), string(value));
    else
        matches(idx) = isequal(currentValue, value);
    end
end
end 

function matches = matchSolverPreset(runs, preset)
runCount = numel(runs);
matches = false(1, runCount);

for idx = 1:runCount
    run = runs(idx);
    if isfield(run, 'solverPreset') && ~isempty(run.solverPreset)
        currentValue = run.solverPreset;
    elseif isfield(run, 'sim') && isfield(run.sim, 'solver') ...
            && isfield(run.sim.solver, 'preset')
        currentValue = run.sim.solver.preset;
    else
        continue;
    end

    if isstring(currentValue) || ischar(currentValue)
        matches(idx) = strcmpi(string(currentValue), string(preset));
    else
        matches(idx) = isequal(currentValue, preset);
    end
end
end
