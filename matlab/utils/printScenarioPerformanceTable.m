function [summaryTable, latexTable] = printScenarioPerformanceTable(databaseFile, opts)
%PRINTSCENARIOPERFORMANCETABLE Print a compact performance summary table.
%   SUMMARYTABLE = PRINTSCENARIOPERFORMANCETABLE(DATABASEFILE) loads the
%   scenario database saved by run_all_scenarios.m, filters runs based on
%   the selection options, and returns a table with trajectory name,
%   controller, parameter set, RMSE, average/max control effort, and
%   trajectory completion time.
%
%   [SUMMARYTABLE, LATEXTABLE] = PRINTSCENARIOPERFORMANCETABLE(...) also
%   returns a LaTeX table string (booktabs-style) suitable for papers.
%
%   Optional name/value pairs:
%     runIndices         - Explicit run indices to include (overrides filters).
%     scenarioNames      - Scenario name(s) to match.
%     trajectoryTypes    - Trajectory preset/handle names to match.
%     trajectoryProfiles - Trajectory profile(s) to match.
%     controllerTypes    - Controller type(s) to match.
%     controllerProfiles - Controller profile(s) to match.
%     solverPresets      - Solver preset(s) to match.
%     showTable          - Toggle console printing.
%     showLatexTable     - Toggle console printing of the LaTeX table.
%     latexCaption       - Caption text for the LaTeX table.
%     latexLabel         - Label tag for the LaTeX table.
%     latexFloatPosition - LaTeX float position (e.g., "htbp").
%     latexColumnFormat  - Column format override (e.g., "lllrccc").
%     latexPrecision     - Numeric precision for LaTeX table output.
%     writeExcel         - Toggle writing a spreadsheet file.
%     excelFile          - Excel output filename (.xlsx). Defaults to the
%                          database folder when writeExcel is true.

arguments
    databaseFile (1, :) char = ''
    opts.runIndices (1, :) double = []
    opts.scenarioNames = []
    opts.trajectoryTypes = []
    opts.trajectoryProfiles = []
    opts.controllerTypes = []
    opts.controllerProfiles = []
    opts.solverPresets = []
    opts.showTable (1, 1) logical = true
    opts.showLatexTable (1, 1) logical = false
    opts.latexCaption (1, :) char = 'Scenario Performance Summary'
    opts.latexLabel (1, :) char = 'tab:scenario-performance'
    opts.latexFloatPosition (1, :) char = 'htbp'
    opts.latexColumnFormat (1, :) char = ''
    opts.latexPrecision (1, 1) double = 3
    opts.writeExcel (1, 1) logical = false
    opts.excelFile (1, :) char = ''
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
    latexTable = "";
    if opts.showTable
        disp('Scenario database is empty.');
        disp(summaryTable);
    end
    if opts.showLatexTable
        disp('LaTeX table:');
        disp(latexTable);
    end
    return;
end

runData = selectRuns(database.runs, opts);
if isempty(runData)
    summaryTable = table();
    latexTable = "";
    if opts.showTable
        disp('No database runs matched the requested parameters.');
        disp(summaryTable);
    end
    if opts.showLatexTable
        disp('LaTeX table:');
        disp(latexTable);
    end
    return;
end

runCount = numel(runData);
summaryTable = table('Size', [runCount, 7], ...
    'VariableTypes', { ...
    'string', 'string', 'string', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', { ...
    'TrajectoryName', 'Controller', 'ParameterSet', 'RMSE', ...
    'ControlEffortMean', 'ControlEffortMax', 'TrajectoryTime'});

for idx = 1:runCount
    run = runData(idx);
    [scenarioName, trajType, trajProfile, controllerType, controllerProfile, ...
        controllerParams] = getRunDescriptors(run);
    metrics = getRunMetrics(run);
    [effortMean, effortPeak] = getControlEffortMetrics(run);

    summaryTable.TrajectoryName(idx) = selectTrajectoryName(...
        scenarioName, trajType, trajProfile);
    summaryTable.Controller(idx) = formatControllerLabel(...
        controllerType, controllerProfile);
    summaryTable.ParameterSet(idx) = selectParameterSet(...
        controllerParams, controllerProfile);
    summaryTable.RMSE(idx) = metrics.rmse;
    summaryTable.ControlEffortMean(idx) = effortMean;
    summaryTable.ControlEffortMax(idx) = effortPeak;
    summaryTable.TrajectoryTime(idx) = metrics.totalTrajectoryTime;
end

if opts.showTable
    disp('Scenario Performance Summary:');
    disp(summaryTable);
end

if opts.writeExcel || ~isempty(opts.excelFile)
    excelFile = resolveExcelFile(opts.excelFile, databaseFile);
    writetable(summaryTable, excelFile);
    if opts.showTable
        fprintf('Saved Excel summary to: %s\n', excelFile);
    end
end

latexTable = formatLatexTable(summaryTable, opts);
if opts.showLatexTable
    disp('LaTeX table:');
    disp(latexTable);
end

end

function excelFile = resolveExcelFile(excelFile, databaseFile)
if ~isempty(excelFile)
    return;
end
baseDir = fileparts(databaseFile);
if isempty(baseDir)
    baseDir = pwd;
end
excelFile = fullfile(baseDir, 'scenario_performance_summary.xlsx');
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
    [scenarioName, trajType, trajProfile, controllerType, controllerProfile, ~, solverPreset] = ...
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

function [scenarioName, trajType, trajProfile, controllerType, controllerProfile, ...
    controllerParams, solverPreset] = getRunDescriptors(run)

scenarioName = "unknown";
trajType = "unknown";
trajProfile = "unknown";
controllerType = "unknown";
controllerProfile = "unknown";
controllerParams = "unknown";
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
    if isfield(scenario, 'controllerParams')
        controllerParams = formatParams(scenario.controllerParams);
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

function name = selectTrajectoryName(scenarioName, trajType, trajProfile)
if ~isempty(trajProfile) && trajProfile ~= "unknown"
    name = trajProfile;
elseif ~isempty(trajType) && trajType ~= "unknown"
    name = trajType;
else
    name = scenarioName;
end
end

function label = formatControllerLabel(controllerType, controllerProfile)
if isempty(controllerProfile) || controllerProfile == "unknown"
    label = controllerType;
else
    label = controllerType + "-" + controllerProfile;
end
end

function paramText = selectParameterSet(controllerParams, controllerProfile)
if isempty(controllerParams) || controllerParams == "unknown"
    paramText = controllerProfile;
else
    paramText = controllerParams;
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

function [effortMean, effortPeak] = getControlEffortMetrics(run)
effortMean = NaN;
effortPeak = NaN;

if ~isfield(run, 'log') || isempty(run.log)
    return;
end

log = run.log;
if ~isfield(log, 'cmdHist') || isempty(log.cmdHist) || size(log.cmdHist, 1) < 5
    return;
end

cmdHist = log.cmdHist;
forces = cmdHist(4:5, :);
controlEffort = sum(forces, 1);

effortMean = mean(controlEffort, 'omitnan');
effortPeak = max(controlEffort, [], 'omitnan');
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

function latexTable = formatLatexTable(summaryTable, opts)
if isempty(summaryTable)
    latexTable = "";
    return;
end

headers = { ...
    'Trajectory', 'Controller', 'Parameters', 'RMSE', ...
    'Mean Effort', 'Max Effort', 'Time (s)'};

columnFormat = opts.latexColumnFormat;
if isempty(columnFormat)
    columnFormat = 'lllrrrc';
end

rowCount = height(summaryTable);
rows = strings(rowCount, 1);
for idx = 1:rowCount
    rowValues = { ...
        summaryTable.TrajectoryName(idx), ...
        summaryTable.Controller(idx), ...
        summaryTable.ParameterSet(idx), ...
        summaryTable.RMSE(idx), ...
        summaryTable.ControlEffortMean(idx), ...
        summaryTable.ControlEffortMax(idx), ...
        summaryTable.TrajectoryTime(idx)};
    rows(idx) = formatLatexRow(rowValues, opts.latexPrecision);
end

latexLines = [
    "\begin{table}[" + string(opts.latexFloatPosition) + "]"
    "\centering"
    "\caption{" + escapeLatex(string(opts.latexCaption)) + "}"
    "\label{" + escapeLatex(string(opts.latexLabel)) + "}"
    "\begin{tabular}{" + string(columnFormat) + "}"
    "\toprule"
    formatLatexHeader(headers)
    rows
    "\bottomrule"
    "\end{tabular}"
    "\end{table}"
    ];

latexTable = strjoin(latexLines, newline);
end

function headerLine = formatLatexHeader(headers)
escaped = cellfun(@(h) escapeLatex(string(h)), headers, 'UniformOutput', false);
headerLine = strjoin(string(escaped), " & ") + " \\";
end

function rowLine = formatLatexRow(values, precision)
formatted = strings(1, numel(values));
for idx = 1:numel(values)
    value = values{idx};
    formatted(idx) = formatLatexValue(value, precision);
end
rowLine = strjoin(formatted, " & ") + " \\";
end

function valueText = formatLatexValue(value, precision)
if isstring(value) || ischar(value)
    valueText = escapeLatex(string(value));
    return;
end
if isnumeric(value) || islogical(value)
    if isscalar(value)
        if isnan(value)
            valueText = "--";
        else
            valueText = string(num2str(value, sprintf('%%.%df', precision)));
        end
    else
        valueText = escapeLatex(string(mat2str(value)));
    end
    return;
end
valueText = escapeLatex(string(value));
end

function text = escapeLatex(text)
text = replace(text, "\", "\\textbackslash ");
text = replace(text, "_", "\_");
text = replace(text, "%", "\%");
text = replace(text, "&", "\&");
text = replace(text, "#", "\#");
text = replace(text, "{", "\{");
text = replace(text, "}", "\}");
text = replace(text, "~", "\textasciitilde ");
text = replace(text, "^", "\textasciicircum ");
end
