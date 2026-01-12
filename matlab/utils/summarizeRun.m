function metrics = summarizeRun(opts)
%SUMMARIZERUN  Print trajectory metrics and plot performance summaries.
%   METRICS = SUMMARIZERUN() computes the trajectory RMSE, plots tracking
%   error versus time with a max-error line, plots control effort, and
%   plots the FFT of the control effort. A metrics struct is returned.

arguments
    opts.showPlots (1, 1) logical = true
    opts.showTable (1, 1) logical = true
end

global state;

metrics = struct('rmse', NaN, ...
    'maxError', NaN, ...
    'minError', NaN, ...
    'totalTrajectoryTime', NaN, ...
    'totalFlightTime', NaN, ...
    'totalWallTime', NaN);

metrics.totalWallTime = resolveWallTime(state);
if isfield(state, 'sim')
    state.sim.wallTime = metrics.totalWallTime;
end

if ~isfield(state, 'qcopter') || isempty(state.qcopter)
    return;
end

traj = state.qcopter.traj;
trajHist = state.qcopter.trajHist;

if isempty(traj) || isempty(trajHist)
    return;
end

tActual = traj(1, :);
actualPos = traj(2:3, :);
tRef = trajHist(1, :);
refPos = trajHist(2:3, :);

[tAligned, errorMag, rmse, maxError] = computeTrajectoryError( ...
    tActual, actualPos, tRef, refPos);

metrics.rmse = rmse;
metrics.maxError = maxError;
if isempty(errorMag)
    metrics.minError = NaN;
else
    metrics.minError = min(errorMag, [], 'omitnan');
end
metrics.totalTrajectoryTime = getTotalDuration(tRef);
metrics.totalFlightTime = getTotalDuration(tActual);

[scenarioName, trajType, trajProfile, controllerType, controllerProfile, controllerParams] = ...
    getScenarioSummary(state);

summaryTable = table( ...
    scenarioName, trajType, trajProfile, controllerType, controllerProfile, controllerParams, ...
    metrics.totalTrajectoryTime, metrics.totalFlightTime, metrics.totalWallTime, ...
    metrics.minError, metrics.maxError, metrics.rmse, ...
    'VariableNames', { ...
    'Scenario', 'TrajectoryType', 'TrajectoryProfile', ...
    'ControllerType', 'ControllerProfile', 'ControllerParams', ...
    'TotalTrajectoryTime', 'TotalFlightTime', 'TotalWallTime', ...
    'MinError', 'MaxError', 'RMSE'});
if opts.showTable
    disp('Run Summary Metrics:');
    disp(summaryTable);
end

if ~opts.showPlots
    return;
end

figure('Name', 'Run Summary', 'NumberTitle', 'off');
tiledlayout(3, 1, 'Padding', 'compact', 'TileSpacing', 'compact');

nexttile(1);
if isempty(tAligned)
    text(0.5, 0.5, 'No trajectory error data available.', ...
        'HorizontalAlignment', 'center');
    axis off;
else
    plot(tAligned, errorMag, 'LineWidth', 1.5);
    hold on;
    yline(maxError, '--r', 'Max Error', 'LabelVerticalAlignment', 'bottom');
    xlabel('Time [s]');
    ylabel('Position Error [m]');
    title('Tracking Error vs Time');
    grid on;
end

[tCmd, controlEffort] = getControlEffort(state);
nexttile(2);
if isempty(tCmd)
    text(0.5, 0.5, 'No control effort data available.', ...
        'HorizontalAlignment', 'center');
    axis off;
else
    plot(tCmd, controlEffort, 'LineWidth', 1.5);
    xlabel('Time [s]');
    ylabel('Control Effort [N]');
    title('Control Effort');
    grid on;
end

nexttile(3);
if isempty(tCmd) || numel(tCmd) < 2
    text(0.5, 0.5, 'No FFT data available.', 'HorizontalAlignment', 'center');
    axis off;
else
    dt = mean(diff(tCmd));
    fs = 1 / dt;
    n = numel(controlEffort);
    controlCentered = controlEffort - mean(controlEffort);
    y = fft(controlCentered);
    p2 = abs(y / n);
    p1 = p2(1:floor(n / 2) + 1);
    f = fs * (0:floor(n / 2)) / n;
    plot(f, p1, 'LineWidth', 1.5);
    xlabel('Frequency [Hz]');
    ylabel('Magnitude');
    title('Control Effort FFT');
    grid on;
end

end

function [tCmd, controlEffort] = getControlEffort(state)
tCmd = [];
controlEffort = [];

if ~isfield(state, 'qcopter') || ~isfield(state.qcopter, 'cmdHist')
    return;
end

cmdHist = state.qcopter.cmdHist;

if isempty(cmdHist) || size(cmdHist, 1) < 5
    return;
end

tCmd = cmdHist(1, :);
forces = cmdHist(4:5, :);
controlEffort = sum(forces, 1);

end

function duration = getTotalDuration(tSeries)
if isempty(tSeries)
    duration = NaN;
    return;
end
duration = tSeries(end) - tSeries(1);
end

function wallTime = resolveWallTime(state)
wallTime = NaN;

if isfield(state, 'sim')
    if isfield(state.sim, 'wallTime') && ~isempty(state.sim.wallTime) ...
            && all(isfinite(state.sim.wallTime))
        wallTime = state.sim.wallTime;
        return;
    end
    if isfield(state.sim, 'wallStart') && ~isempty(state.sim.wallStart)
        try
            wallTime = toc(state.sim.wallStart);
            return;
        catch
        end
    end
end
end

function [scenarioName, trajType, trajProfile, controllerType, controllerProfile, controllerParams] = ...
    getScenarioSummary(state)
scenarioName = "unknown";
trajType = "unknown";
trajProfile = "unknown";
controllerType = "unknown";
controllerProfile = "unknown";
controllerParams = "unknown";

if ~isfield(state, 'scenario') || isempty(state.scenario)
    return;
end

scenario = state.scenario;

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
