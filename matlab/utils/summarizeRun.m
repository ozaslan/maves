function metrics = summarizeRun()
%SUMMARIZERUN  Print trajectory metrics and plot performance summaries.
%   METRICS = SUMMARIZERUN() computes the trajectory RMSE, plots tracking
%   error versus time with a max-error line, plots control effort, and
%   plots the FFT of the control effort. A metrics struct is returned.

global state;

metrics = struct('rmse', NaN, 'maxError', NaN);

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

summaryTable = table(rmse, maxError, 'VariableNames', {'RMSE', 'MaxError'});
disp('Run Summary Metrics:');
disp(summaryTable);

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
