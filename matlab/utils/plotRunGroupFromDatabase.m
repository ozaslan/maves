function [runData, metrics] = plotRunGroupFromDatabase(databaseFile, opts)
%PLOTRUNGROUPFROMDATABASE Plot multiple runs from the scenario database.
%   [RUNDATA, METRICS] = PLOTRUNGROUPFROMDATABASE(DATABASEFILE) loads the
%   scenario database saved by run_all_scenarios.m, filters runs based on
%   the selection options, and plots tracking error, control effort, and
%   RMSE on a shared figure with multiple subplots.
%
%   Optional name/value pairs:
%     runIndices         - Explicit run indices to plot (overrides filters).
%     scenarioNames      - Scenario name(s) to match.
%     trajectoryTypes    - Trajectory preset/handle names to match.
%     trajectoryProfiles - Trajectory profile(s) to match.
%     controllerTypes    - Controller type(s) to match.
%     controllerProfiles - Controller profile(s) to match.
%     solverPresets      - Solver preset(s) to match.
%     showLegend         - Toggle legend display.

arguments
    databaseFile (1, :) char = ''
    opts.runIndices (1, :) double = []
    opts.scenarioNames = []
    opts.trajectoryTypes = []
    opts.trajectoryProfiles = []
    opts.controllerTypes = []
    opts.controllerProfiles = []
    opts.solverPresets = []
    opts.showLegend (1, 1) logical = true
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

runData = selectRuns(database.runs, opts);
if isempty(runData)
    error('No database runs matched the requested parameters.');
end

[errorSeries, controlSeries, rmseValues, labels] = ...
    collectRunSeries(runData);

fig = figure('Name', 'Database Run Group Summary', 'NumberTitle', 'off');
tiledlayout(fig, 3, 1, 'Padding', 'compact', 'TileSpacing', 'compact');

plotTrackingErrors(errorSeries, labels, opts.showLegend);
plotControlEfforts(controlSeries, labels);
plotRmse(rmseValues, labels);

metrics = struct('labels', labels, ...
    'trackingError', errorSeries, ...
    'controlEffort', controlSeries, ...
    'rmse', rmseValues);

end

function runData = selectRuns(runs, opts)
runCount = numel(runs);

if ~isempty(opts.runIndices)
    indices = unique(opts.runIndices(:)');
    if any(indices < 1) || any(indices > runCount)
        error('runIndices must be between 1 and %d.', runCount);
    end
    runData = runs(indices);
    return;
end

scenarioNames = normalizeStringList(opts.scenarioNames);
trajTypes = normalizeTrajTypeList(opts.trajectoryTypes);
trajProfiles = normalizeStringList(opts.trajectoryProfiles);
controllerTypes = normalizeStringList(opts.controllerTypes);
controllerProfiles = normalizeStringList(opts.controllerProfiles);
solverPresets = normalizeStringList(opts.solverPresets);

matches = true(1, runCount);
for idx = 1:runCount
    run = runs(idx);
    [scenarioName, trajType, trajProfile, controllerType, controllerProfile, solverPreset] = ...
        getRunDescriptors(run);
    trajType = normalizeTrajType(trajType);
    matches(idx) = matches(idx) ...
        && matchList(scenarioName, scenarioNames) ...
        && matchList(trajType, trajTypes) ...
        && matchList(trajProfile, trajProfiles) ...
        && matchList(controllerType, controllerTypes) ...
        && matchList(controllerProfile, controllerProfiles) ...
        && matchList(solverPreset, solverPresets);
end

runData = runs(matches);
end

function [scenarioName, trajType, trajProfile, controllerType, controllerProfile, solverPreset] = ...
    getRunDescriptors(run)

scenarioName = "unknown";
trajType = "unknown";
trajProfile = "unknown";
controllerType = "unknown";
controllerProfile = "unknown";
solverPreset = "unknown";

if isfield(run, 'scenarioName') && ~isempty(run.scenarioName)
    scenarioName = string(run.scenarioName);
end

if isfield(run, 'scenario') && ~isempty(run.scenario)
    scenario = run.scenario;
    if isfield(scenario, 'name') && ~isempty(scenario.name)
        scenarioName = string(scenario.name);
    end
    if isfield(scenario, 'trajPreset') && ~isempty(scenario.trajPreset)
        trajType = string(func2str(scenario.trajPreset));
    elseif isfield(scenario, 'trajHandle') && ~isempty(scenario.trajHandle)
        trajType = string(func2str(scenario.trajHandle));
    end
    if isfield(scenario, 'trajProfile') && ~isempty(scenario.trajProfile)
        trajProfile = string(scenario.trajProfile);
    end
    if isfield(scenario, 'controllerType') && ~isempty(scenario.controllerType)
        controllerType = string(scenario.controllerType);
    end
    if isfield(scenario, 'controllerProfile') && ~isempty(scenario.controllerProfile)
        controllerProfile = string(scenario.controllerProfile);
    end
end

if isfield(run, 'solverPreset') && ~isempty(run.solverPreset)
    solverPreset = string(run.solverPreset);
elseif isfield(run, 'sim') && isfield(run.sim, 'solver') ...
        && isfield(run.sim.solver, 'preset') && ~isempty(run.sim.solver.preset)
    solverPreset = string(run.sim.solver.preset);
end

end

function values = normalizeStringList(values)
if isempty(values)
    values = string.empty(1, 0);
    return;
end
if ischar(values) || isstring(values)
    values = string(values);
elseif iscell(values)
    values = string(values);
else
    values = string(values);
end
values = strip(values);
values = values(values ~= "");
end

function values = normalizeTrajTypeList(values)
values = normalizeStringList(values);
if isempty(values)
    return;
end
values = arrayfun(@normalizeTrajType, values);
values = values(values ~= "");
end

function value = normalizeTrajType(value)
if isempty(value)
    value = "";
    return;
end
value = lower(strtrim(string(value)));
value = regexprep(value, '^trajpreset', '');
value = regexprep(value, '^traj', '');
value = strtrim(value);
end

function matches = matchList(value, validValues)
if isempty(validValues)
    matches = true;
    return;
end
if isempty(value)
    matches = false;
    return;
end
matches = any(strcmpi(string(value), validValues));
end

function [errorSeries, controlSeries, rmseValues, labels] = collectRunSeries(runData)
runCount = numel(runData);
errorSeries = repmat(struct('t', [], 'error', []), 1, runCount);
controlSeries = repmat(struct('t', [], 'effort', []), 1, runCount);
rmseValues = NaN(1, runCount);
labels = strings(1, runCount);

for idx = 1:runCount
    run = runData(idx);
    [scenarioName, trajType, trajProfile, controllerType, controllerProfile, solverPreset] = ...
        getRunDescriptors(run);
    labels(idx) = formatRunLabel(scenarioName, trajType, trajProfile, ...
        controllerType, controllerProfile, solverPreset);

    if isfield(run, 'log') && ~isempty(run.log)
        log = run.log;
        if isfield(log, 'traj') && isfield(log, 'trajHist') ...
                && ~isempty(log.traj) && ~isempty(log.trajHist)
            traj = log.traj;
            trajHist = log.trajHist;
            tActual = traj(1, :);
            actualPos = traj(2:3, :);
            tRef = trajHist(1, :);
            refPos = trajHist(2:3, :);
            [tAligned, errorMag, rmse] = computeTrajectoryError( ...
                tActual, actualPos, tRef, refPos);
            errorSeries(idx).t = tAligned;
            errorSeries(idx).error = errorMag;
            rmseValues(idx) = rmse;
        end

        if isfield(log, 'cmdHist') && ~isempty(log.cmdHist) ...
                && size(log.cmdHist, 1) >= 5
            cmdHist = log.cmdHist;
            tCmd = cmdHist(1, :);
            forces = cmdHist(4:5, :);
            controlEffort = sum(forces, 1);
            controlSeries(idx).t = tCmd;
            controlSeries(idx).effort = controlEffort;
        end
    end
end
end

function plotTrackingErrors(errorSeries, labels, showLegend)
ax = nexttile(1);
hold(ax, 'on');
grid(ax, 'on');
title(ax, 'Tracking Error vs Time');
xlabel(ax, 'Time [s]');
ylabel(ax, 'Position Error [m]');

colors = lines(numel(errorSeries));
plotted = false;
for idx = 1:numel(errorSeries)
    if isempty(errorSeries(idx).t) || isempty(errorSeries(idx).error)
        continue;
    end
    plotted = true;
    plot(ax, errorSeries(idx).t, errorSeries(idx).error, ...
        'LineWidth', 1.5, ...
        'Color', colors(idx, :), ...
        'DisplayName', labels(idx));
end

if ~plotted
    text(ax, 0.5, 0.5, 'No tracking error data available.', ...
        'HorizontalAlignment', 'center', 'Units', 'normalized');
end

if showLegend && plotted
    legend(ax, 'Location', 'best');
end
end

function plotControlEfforts(controlSeries, labels)
ax = nexttile(2);
hold(ax, 'on');
grid(ax, 'on');
title(ax, 'Control Effort');
xlabel(ax, 'Time [s]');
ylabel(ax, 'Control Effort [N]');

colors = lines(numel(controlSeries));
plotted = false;
for idx = 1:numel(controlSeries)
    if isempty(controlSeries(idx).t) || isempty(controlSeries(idx).effort)
        continue;
    end
    plotted = true;
    plot(ax, controlSeries(idx).t, controlSeries(idx).effort, ...
        'LineWidth', 1.5, ...
        'Color', colors(idx, :), ...
        'DisplayName', labels(idx));
end

if ~plotted
    text(ax, 0.5, 0.5, 'No control effort data available.', ...
        'HorizontalAlignment', 'center', 'Units', 'normalized');
end
end

function plotRmse(rmseValues, labels)
ax = nexttile(3);
hold(ax, 'on');
grid(ax, 'on');
title(ax, 'RMSE');
xlabel(ax, 'Run Index');
ylabel(ax, 'RMSE [m]');

colors = lines(numel(rmseValues));
validMask = isfinite(rmseValues);
if ~any(validMask)
    text(ax, 0.5, 0.5, 'No RMSE data available.', ...
        'HorizontalAlignment', 'center', 'Units', 'normalized');
    return;
end

for idx = 1:numel(rmseValues)
    if ~isfinite(rmseValues(idx))
        continue;
    end
    plot(ax, idx, rmseValues(idx), 'o', ...
        'MarkerSize', 7, ...
        'MarkerFaceColor', colors(idx, :), ...
        'MarkerEdgeColor', colors(idx, :), ...
        'DisplayName', labels(idx));
end

ax.XLim = [0.5, numel(rmseValues) + 0.5];
ax.XTick = 1:numel(rmseValues);
ax.XTickLabel = cellstr(compose('%d', 1:numel(rmseValues)));
end

function label = formatRunLabel(scenarioName, trajType, trajProfile, ...
    controllerType, controllerProfile, solverPreset)

tokens = [
    abbreviateToken(trajType)
    abbreviateToken(trajProfile)
    abbreviateToken(controllerType)
    abbreviateToken(controllerProfile)
    abbreviateToken(solverPreset)
    ];

tokens = tokens(tokens ~= "");
if isempty(tokens)
    label = abbreviateToken(scenarioName);
else
    label = strjoin(tokens, "-");
end
end

function token = abbreviateToken(value)
if isempty(value)
    token = "";
    return;
end

value = string(value);
if value == ""
    token = "";
    return;
end

lowerValue = lower(value);
switch lowerValue
    case "line"
        token = "LN";
    case "circle"
        token = "CIR";
    case "diamond"
        token = "DIA";
    case "lqr"
        token = "LQR";
    case "pid"
        token = "PID";
    case "mpc"
        token = "MPC";
    case "fast"
        token = "FST";
    case "balanced"
        token = "BAL";
    case "accurate"
        token = "ACC";
    otherwise
        parts = regexp(lowerValue, '[^a-z0-9]+', 'split');
        parts = parts(~cellfun(@isempty, parts));
        if isempty(parts)
            maxLen = min(strlength(value), 4);
            token = upper(extractBefore(value, maxLen + 1));
        else
            token = upper(join(string(cellfun(@(c) c(1), parts, 'UniformOutput', false)), ""));
            if strlength(token) > 5
                token = extractBefore(token, 6);
            end
        end
end
end
