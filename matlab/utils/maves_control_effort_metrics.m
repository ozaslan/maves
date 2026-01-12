function metrics = maves_control_effort_metrics(psdData, params)
%MAVES_CONTROL_EFFORT_METRICS  Compute control effort metrics from PSDs.
%   METRICS = MAVES_CONTROL_EFFORT_METRICS(PSDDATA, PARAMS) returns a table
%   of time-domain and frequency-domain metrics (J1, J2, J3) for each motor
%   and aggregate thrust signal, supporting the MAVES paper claim that
%   higher gains yield more high-frequency motor force activity.

if nargin < 2 || isempty(params)
    params = struct();
end

if ~isfield(params, 'cutoffsHz') || isempty(params.cutoffsHz)
    params.cutoffsHz = [20 30 50];
end

metrics = table();
if isempty(psdData) || ~isfield(psdData, 'signals')
    warning('maves_control_effort_metrics:MissingData', ...
        'No PSD data available to compute metrics.');
    return;
end

signalNames = fieldnames(psdData.signals);
rows = [];
for idx = 1:numel(signalNames)
    signal = psdData.signals.(signalNames{idx});
    if isempty(signal) || isempty(signal.t) || isempty(signal.x)
        continue;
    end
    [j1, j2] = computeTimeMetrics(signal.t, signal.x);
    j3 = computeFrequencyMetrics(signal.f, signal.Pxx, params.cutoffsHz);
    row = [j1 j2 j3(:)'];
    rows = [rows; row]; %#ok<AGROW>
end

if isempty(rows)
    return;
end

varNames = [{'J1_IntF2', 'J2_IntDF2'}, arrayfun(@(c) ...
    sprintf('J3_PSD_gt_%gHz', c), params.cutoffsHz, 'UniformOutput', false)];
metrics = array2table(rows, 'VariableNames', varNames);
metrics.Signal = signalNames(:);
metrics = movevars(metrics, 'Signal', 'Before', 1);

end

function [j1, j2] = computeTimeMetrics(t, x)
if numel(t) < 2 || numel(x) < 2
    j1 = NaN;
    j2 = NaN;
    return;
end

x = x(:);
t = t(:);

j1 = trapz(t, x .^ 2);
dx = gradient(x, t);
j2 = trapz(t, dx .^ 2);
end

function j3 = computeFrequencyMetrics(f, Pxx, cutoffs)
if isempty(f) || isempty(Pxx)
    j3 = NaN(size(cutoffs));
    return;
end

j3 = zeros(size(cutoffs));
for idx = 1:numel(cutoffs)
    fc = cutoffs(idx);
    mask = f > fc;
    if any(mask)
        j3(idx) = trapz(f(mask), Pxx(mask));
    else
        j3(idx) = 0;
    end
end
end
