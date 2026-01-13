function [groupData, metrics] = plotRunGroupTrackingSubplotsFromDatabase(databaseFile, groupFilters, opts)
%PLOTRUNGROUPTRACKINGSUBPLOTSFROMDATABASE Plot tracking error subplots per filter group.
%   [GROUPDATA, METRICS] = PLOTRUNGROUPTRACKINGSUBPLOTSFROMDATABASE(DATABASEFILE,
%   GROUPFILTERS) loads the scenario database saved by run_all_scenarios.m,
%   applies each filter group to select runs, and plots tracking error
%   subplots for each group on a shared figure.
%
%   GROUPFILTERS can be a struct array or cell array of structs with fields:
%     runIndices
%     scenarioNames
%     trajectoryTypes
%     trajectoryProfiles
%     controllerTypes
%     controllerProfiles
%     solverPresets
%     title (optional subplot title)
%
%   Optional name/value pairs:
%     showLegend   - Toggle legend display.
%     groupTitles  - Override titles for each group.

arguments
    databaseFile (1, :) char = ''
    groupFilters = {}
    opts.showLegend (1, 1) logical = true
    opts.groupTitles = []
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

if isempty(groupFilters)
    error('groupFilters must contain at least one filter group.');
end

if isstruct(groupFilters)
    groupFilters = num2cell(groupFilters);
end

runs = database.runs;
groupCount = numel(groupFilters);

[rows, cols] = layoutForCount(groupCount);
fig = figure('Name', 'Database Tracking Error Groups', 'NumberTitle', 'off');
tiledlayout(fig, rows, cols, 'Padding', 'compact', 'TileSpacing', 'compact');

groupData = cell(1, groupCount);
metrics = repmat(struct('labels', [], 'trackingError', [], 'groupTitle', ''), 1, groupCount);

for idx = 1:groupCount
    groupOpts = normalizeGroupOptions(groupFilters{idx});
    runData = selectRuns(runs, groupOpts);
    [errorSeries, labels] = collectRunErrorSeries(runData);
    groupTitle = resolveGroupTitle(groupOpts, opts.groupTitles, idx);

    plotTrackingErrorsSubplot(errorSeries, labels, opts.showLegend, groupTitle);

    groupData{idx} = runData;
    metrics(idx).labels = labels;
    metrics(idx).trackingError = errorSeries;
    metrics(idx).groupTitle = groupTitle;
end

end

function groupOpts = normalizeGroupOptions(groupOpts)
if isempty(groupOpts)
    groupOpts = struct();
end
if ~isstruct(groupOpts)
    error('Each group filter must be a struct.');
end

fields = { ...
    'runIndices', ...
    'scenarioNames', ...
    'trajectoryTypes', ...
    'trajectoryProfiles', ...
    'controllerTypes', ...
    'controllerProfiles', ...
    'solverPresets' ...
    };

for idx = 1:numel(fields)
    fieldName = fields{idx};
    if ~isfield(groupOpts, fieldName)
        groupOpts.(fieldName) = [];
    end
end

if ~isfield(groupOpts, 'title')
    groupOpts.title = '';
end
end

function [rows, cols] = layoutForCount(count)
cols = 1;
rows = max(1, count);
end

function titleText = resolveGroupTitle(groupOpts, groupTitles, idx)
if ~isempty(groupTitles)
    if iscell(groupTitles) || isstring(groupTitles)
        groupTitles = string(groupTitles);
        if idx <= numel(groupTitles)
            titleText = groupTitles(idx);
            return;
        end
    end
end

if isfield(groupOpts, 'title') && ~isempty(groupOpts.title)
    titleText = string(groupOpts.title);
else
    titleText = "Tracking Error Group " + idx;
end
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
controllerTypes = normalizeControllerTypeList(opts.controllerTypes);
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

controllerType = normalizeControllerType(controllerType);

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

function values = normalizeControllerTypeList(values)
values = normalizeStringList(values);
if isempty(values)
    return;
end
values = arrayfun(@normalizeControllerType, values);
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

function value = normalizeControllerType(value)
if isempty(value)
    value = "";
    return;
end
if isa(value, 'function_handle')
    value = func2str(value);
end
value = lower(strtrim(string(value)));
value = regexprep(value, '^@', '');
value = regexprep(value, '^controller_?', '');
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

function [errorSeries, labels] = collectRunErrorSeries(runData)
runCount = numel(runData);
errorSeries = repmat(struct('t', [], 'error', [], 'intendedTime', []), 1, runCount);
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
            [tAligned, errorMag] = computeTrajectoryError( ...
                tActual, actualPos, tRef, refPos);
            errorSeries(idx).t = tAligned;
            errorSeries(idx).error = errorMag;
            if ~isempty(tRef)
                errorSeries(idx).intendedTime = tRef(end);
            end
        end
    end

    if isempty(errorSeries(idx).intendedTime)
        errorSeries(idx).intendedTime = extractIntendedTime(run);
    end
end
end

function plotTrackingErrorsSubplot(errorSeries, labels, showLegend, plotTitle)
ax = nexttile();
hold(ax, 'on');
grid(ax, 'on');
if plotTitle == ""
    title(ax, 'Tracking Error vs Time');
else
    title(ax, plotTitle);
end
xlabel(ax, 'Time [s]');
ylabel(ax, 'Position Error [m]');

colors = lines(max(1, numel(errorSeries)));
plotted = false;
for idx = 1:numel(errorSeries)
    if isempty(errorSeries(idx).t) || isempty(errorSeries(idx).error)
        continue;
    end
    plotted = true;
    plot(ax, errorSeries(idx).t, errorSeries(idx).error, ...
        'LineWidth', 1.5, ...
        'LineStyle', '-', ...
        'Marker', 'none', ...
        'Color', colors(idx, :), ...
        'DisplayName', labels(idx));
    if ~isempty(errorSeries(idx).intendedTime)
        xline(ax, errorSeries(idx).intendedTime, ...
            'Color', colors(idx, :), ...
            'LineStyle', '-', ...
            'HandleVisibility', 'off');
    end
end

if ~plotted
    text(ax, 0.5, 0.5, 'No tracking error data available.', ...
        'HorizontalAlignment', 'center', 'Units', 'normalized');
end

if showLegend && plotted
    legend(ax, 'Location', 'northeast');
end
if plotted
    yLimits = ylim(ax);
    ylim(ax, [min(yLimits(1), -0.05), yLimits(2)]);
end
end

function intendedTime = extractIntendedTime(run)
intendedTime = [];
if isfield(run, 'scenario') && ~isempty(run.scenario)
    scenario = run.scenario;
    if isfield(scenario, 'trajParams') && ~isempty(scenario.trajParams)
        params = scenario.trajParams;
        if isstruct(params) && isfield(params, 'tEnd') && ~isempty(params.tEnd)
            intendedTime = params.tEnd;
        end
    end
end
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
