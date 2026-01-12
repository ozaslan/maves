function summaryTable = printScenarioDatabaseTable(databaseFile, opts)
%PRINTSCENARIODATABASETABLE Print a publication-ready summary table.
%   SUMMARYTABLE = PRINTSCENARIODATABASETABLE(DATABASEFILE) loads the
%   scenario database saved by run_all_scenarios.m and prints a table of
%   configuration and performance metrics suitable for reporting. The table
%   is also returned to the caller.
%
%   SUMMARYTABLE = PRINTSCENARIODATABASETABLE(..., 'showTable', false)
%   suppresses printing to the console.

arguments
    databaseFile (1, :) char = ''
    opts.showTable (1, 1) logical = true
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
    summaryTable = table();
    if opts.showTable
        disp('Scenario database is empty.');
        disp(summaryTable);
    end
    return;
end

runs = database.runs;
runCount = numel(runs);

summaryTable = table('Size', [runCount, 27], ...
    'VariableTypes', { ...
    'double', ...
    'string', 'string', 'string', 'string', 'string', 'string', 'string', ...
    'string', 'string', 'string', 'string', ...
    'double', 'double', 'double', ...
    'string', ...
    'double', 'double', 'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double'}, ...
    'VariableNames', { ...
    'RunIndex', 'Scenario', 'TrajectoryType', 'TrajectoryProfile', 'TrajectoryParams', ...
    'ControllerType', 'ControllerProfile', 'ControllerParams', 'VisualizationMode', ...
    'CaptureMode', 'SolverPreset', 'SolverMethod', 'SolverTimeStep', ...
    'SolverRelTol', 'SolverAbsTol', 'GeneratedAt', 'SimSteps', ...
    'TotalTrajectoryTime', 'TotalFlightTime', 'TotalWallTime', 'MinError', ...
    'MaxError', 'RMSE', 'ControlEffortMean', 'ControlEffortRms', ...
    'ControlEffortPeak', 'ControlEffortImpulse'});

generatedAt = string(NaT);
if isfield(database, 'generatedAt') && ~isempty(database.generatedAt)
    generatedAt = string(database.generatedAt);
end

for idx = 1:runCount
    run = runs(idx);
    [scenarioName, trajType, trajProfile, trajParams, controllerType, ...
        controllerProfile, controllerParams, visualizationMode, captureMode] = ...
        getScenarioDetails(run);
    [solverPreset, solverMethod, solverTimeStep, solverRelTol, solverAbsTol] = ...
        getSolverDetails(run);
    metrics = getRunMetrics(run);
    [effortMean, effortRms, effortPeak, effortImpulse] = getControlEffortMetrics(run);
    simSteps = getSimSteps(run);

    summaryTable.RunIndex(idx) = idx;
    summaryTable.Scenario(idx) = scenarioName;
    summaryTable.TrajectoryType(idx) = trajType;
    summaryTable.TrajectoryProfile(idx) = trajProfile;
    summaryTable.TrajectoryParams(idx) = trajParams;
    summaryTable.ControllerType(idx) = controllerType;
    summaryTable.ControllerProfile(idx) = controllerProfile;
    summaryTable.ControllerParams(idx) = controllerParams;
    summaryTable.VisualizationMode(idx) = visualizationMode;
    summaryTable.CaptureMode(idx) = captureMode;
    summaryTable.SolverPreset(idx) = solverPreset;
    summaryTable.SolverMethod(idx) = solverMethod;
    summaryTable.SolverTimeStep(idx) = solverTimeStep;
    summaryTable.SolverRelTol(idx) = solverRelTol;
    summaryTable.SolverAbsTol(idx) = solverAbsTol;
    summaryTable.GeneratedAt(idx) = generatedAt;
    summaryTable.SimSteps(idx) = simSteps;
    summaryTable.TotalTrajectoryTime(idx) = metrics.totalTrajectoryTime;
    summaryTable.TotalFlightTime(idx) = metrics.totalFlightTime;
    summaryTable.TotalWallTime(idx) = metrics.totalWallTime;
    summaryTable.MinError(idx) = metrics.minError;
    summaryTable.MaxError(idx) = metrics.maxError;
    summaryTable.RMSE(idx) = metrics.rmse;
    summaryTable.ControlEffortMean(idx) = effortMean;
    summaryTable.ControlEffortRms(idx) = effortRms;
    summaryTable.ControlEffortPeak(idx) = effortPeak;
    summaryTable.ControlEffortImpulse(idx) = effortImpulse;
end

if opts.showTable
    disp('Scenario Database Summary:');
    disp(summaryTable);
end

end

function [scenarioName, trajType, trajProfile, trajParams, controllerType, ...
    controllerProfile, controllerParams, visualizationMode, captureMode] = ...
    getScenarioDetails(run)

scenarioName = "unknown";
trajType = "unknown";
trajProfile = "unknown";
trajParams = "unknown";
controllerType = "unknown";
controllerProfile = "unknown";
controllerParams = "unknown";
visualizationMode = "unknown";
captureMode = "unknown";

if isfield(run, 'scenarioName') && ~isempty(run.scenarioName)
    scenarioName = string(run.scenarioName);
end

if ~isfield(run, 'scenario') || isempty(run.scenario)
    return;
end

scenario = run.scenario;

if isfield(scenario, 'trajPreset') && ~isempty(scenario.trajPreset)
    trajType = string(func2str(scenario.trajPreset));
elseif isfield(scenario, 'trajHandle') && ~isempty(scenario.trajHandle)
    trajType = string(func2str(scenario.trajHandle));
end
if isfield(scenario, 'trajProfile') && ~isempty(scenario.trajProfile)
    trajProfile = string(scenario.trajProfile);
end
if isfield(scenario, 'trajParams')
    trajParams = formatParams(scenario.trajParams);
end
if isfield(scenario, 'controllerType') && ~isempty(scenario.controllerType)
    controllerType = string(scenario.controllerType);
end
if isfield(scenario, 'controllerProfile') && ~isempty(scenario.controllerProfile)
    controllerProfile = string(scenario.controllerProfile);
end
if isfield(scenario, 'controllerParams')
    controllerParams = formatParams(scenario.controllerParams);
end
if isfield(scenario, 'visualizationMode') && ~isempty(scenario.visualizationMode)
    visualizationMode = string(scenario.visualizationMode);
end
if isfield(scenario, 'captureMode') && ~isempty(scenario.captureMode)
    captureMode = string(scenario.captureMode);
end

end

function metrics = getRunMetrics(run)
metrics = struct('rmse', NaN, ...
    'maxError', NaN, ...
    'minError', NaN, ...
    'totalTrajectoryTime', NaN, ...
    'totalFlightTime', NaN, ...
    'totalWallTime', NaN);

if isfield(run, 'metrics') && ~isempty(run.metrics)
    runMetrics = run.metrics;
    fields = fieldnames(metrics);
    for idx = 1:numel(fields)
        field = fields{idx};
        if isfield(runMetrics, field)
            metrics.(field) = runMetrics.(field);
        end
    end
end
end

function [preset, method, timeStep, relTol, absTol] = getSolverDetails(run)
preset = "unknown";
method = "unknown";
timeStep = NaN;
relTol = NaN;
absTol = NaN;

if ~isfield(run, 'sim') || isempty(run.sim) || ~isfield(run.sim, 'solver')
    return;
end

solverCfg = run.sim.solver;
if isfield(solverCfg, 'preset') && ~isempty(solverCfg.preset)
    preset = string(solverCfg.preset);
end
if isfield(solverCfg, 'method') && ~isempty(solverCfg.method)
    method = string(solverCfg.method);
end
if isfield(solverCfg, 'timeStep') && ~isempty(solverCfg.timeStep)
    timeStep = solverCfg.timeStep;
end
if isfield(solverCfg, 'relTol') && ~isempty(solverCfg.relTol)
    relTol = solverCfg.relTol;
end
if isfield(solverCfg, 'absTol') && ~isempty(solverCfg.absTol)
    absTol = solverCfg.absTol;
end
end

function simSteps = getSimSteps(run)
simSteps = NaN;
if isfield(run, 'sim') && ~isempty(run.sim)
    if isfield(run.sim, 'step')
        simSteps = run.sim.step;
    end
end
end

function [effortMean, effortRms, effortPeak, effortImpulse] = getControlEffortMetrics(run)
effortMean = NaN;
effortRms = NaN;
effortPeak = NaN;
effortImpulse = NaN;

if ~isfield(run, 'log') || isempty(run.log)
    return;
end

log = run.log;
if ~isfield(log, 'cmdHist') || isempty(log.cmdHist) || size(log.cmdHist, 1) < 5
    return;
end

cmdHist = log.cmdHist;
tCmd = cmdHist(1, :);
forces = cmdHist(4:5, :);
controlEffort = sum(forces, 1);

effortMean = mean(controlEffort, 'omitnan');
effortRms = sqrt(mean(controlEffort .^ 2, 'omitnan'));
effortPeak = max(controlEffort, [], 'omitnan');

if numel(tCmd) > 1
    dt = mean(diff(tCmd));
    effortImpulse = sum(controlEffort, 'omitnan') * dt;
end
end

function valueText = formatParams(value)
if isempty(value)
    valueText = "[]";
    return;
end
if isstring(value) || ischar(value)
    valueText = string(value);
    return;
end
if isnumeric(value) || islogical(value)
    valueText = string(mat2str(value));
    return;
end
if isstruct(value)
    if exist('jsonencode', 'builtin') == 5 || exist('jsonencode', 'file') == 2
        valueText = string(jsonencode(value));
    else
        valueText = string(strtrim(evalc('disp(value)')));
    end
    return;
end
if iscell(value)
    valueText = string(strtrim(evalc('disp(value)')));
    return;
end
valueText = string(class(value));
end
