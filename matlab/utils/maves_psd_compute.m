function psdData = maves_psd_compute(log, params)
%MAVES_PSD_COMPUTE  Compute PSDs of motor thrust signals from MAVES logs.
%   PSDDATA = MAVES_PSD_COMPUTE(LOG, PARAMS) computes Welch PSDs for the
%   motor thrust/force signals F1 and F2 (and aggregate signals) to quantify
%   high-frequency control effort consistent with the MAVES paper narrative.

params = applyDefaults(params);

[signals, meta] = extractSignals(log, params);
if isempty(signals)
    warning('maves_psd_compute:MissingSignals', ...
        'No motor force signals available to compute PSDs.');
    psdData = struct('signals', struct(), 'fs', NaN, 'meta', meta, ...
        'params', params);
    return;
end

psdData = struct('signals', struct(), 'fs', meta.fs, 'meta', meta, ...
    'params', params);

signalNames = fieldnames(signals);
for idx = 1:numel(signalNames)
    name = signalNames{idx};
    signal = signals.(name);
    if isempty(signal.t) || isempty(signal.x)
        continue;
    end
    [f, Pxx] = computeWelch(signal.x, meta.fs, params);
    psdData.signals.(name) = struct('name', name, 't', signal.t, ...
        'x', signal.x, 'f', f, 'Pxx', Pxx);
end

end

function [f, Pxx] = computeWelch(x, fs, params)
if numel(x) < 2 || isnan(fs) || fs <= 0
    f = [];
    Pxx = [];
    return;
end

if params.detrend
    x = detrend(x);
else
    x = x - mean(x);
end

nWindow = max(4, round(params.windowSec * fs));
nWindow = min(nWindow, numel(x));
window = hamming(nWindow);
noverlap = floor(params.overlapFrac * nWindow);

if isempty(params.nfft)
    nfft = max(256, 2 ^ nextpow2(nWindow));
else
    nfft = params.nfft;
end

[Pxx, f] = pwelch(x, window, noverlap, nfft, fs);
end

function [signals, meta] = extractSignals(log, params)
signals = struct();
meta = struct('fs', NaN, 'tWindow', params.tWindow, 'source', '');

if isempty(log)
    return;
end

[t, f1, f2, source] = resolveMotorForces(log, params);
if isempty(t) || isempty(f1) || isempty(f2)
    return;
end

mask = true(size(t));
if ~isempty(params.tWindow) && numel(params.tWindow) == 2
    mask = t >= params.tWindow(1) & t <= params.tWindow(2);
end

t = t(mask);
f1 = f1(mask);
f2 = f2(mask);

fs = params.fs;
if isempty(fs) || isnan(fs)
    dt = median(diff(t));
    if isempty(dt) || dt <= 0
        fs = NaN;
    else
        fs = 1 / dt;
    end
end

meta.fs = fs;
meta.source = source;

signals.F1 = struct('t', t, 'x', f1);
signals.F2 = struct('t', t, 'x', f2);
signals.Fsum = struct('t', t, 'x', f1 + f2);
signals.Fn = struct('t', t, 'x', hypot(f1, f2));

end

function [t, f1, f2, source] = resolveMotorForces(log, params)
t = [];
f1 = [];
f2 = [];
source = '';

if isstruct(log)
    t = getField(log, {'t', 'time', 'stamp'});
    f1 = getField(log, {'F1', 'f1', 'motor1', 'force1'});
    f2 = getField(log, {'F2', 'f2', 'motor2', 'force2'});
    if ~isempty(t) && ~isempty(f1) && ~isempty(f2)
        source = 'direct';
        t = t(:)';
        f1 = f1(:)';
        f2 = f2(:)';
        return;
    end

    cmdHist = getField(log, {'cmdHist', 'cmd_history'});
    if ~isempty(cmdHist) && size(cmdHist, 1) >= 5
        t = cmdHist(1, :);
        f1 = cmdHist(4, :);
        f2 = cmdHist(5, :);
        source = 'cmdHist';
        return;
    end

    traj = getField(log, {'traj', 'stateHist'});
    if ~isempty(traj) && size(traj, 1) >= 9
        kF = resolveKF(log, params);
        if ~isempty(kF)
            t = traj(1, :);
            w1 = traj(8, :);
            w2 = traj(9, :);
            f1 = kF * (w1 .^ 2);
            f2 = kF * (w2 .^ 2);
            source = 'traj';
            return;
        end
    end
end

end

function kF = resolveKF(log, params)
kF = [];
if isfield(params, 'kF') && ~isempty(params.kF)
    kF = params.kF;
    return;
end

if isstruct(log)
    kF = getField(log, {'kF', 'k_f'});
    if ~isempty(kF)
        return;
    end
    if isfield(log, 'params') && isfield(log.params, 'qcopter') && ...
            isfield(log.params.qcopter, 'phys') && ...
            isfield(log.params.qcopter.phys, 'kF')
        kF = log.params.qcopter.phys.kF;
    end
end
end

function value = getField(log, names)
value = [];
for idx = 1:numel(names)
    name = names{idx};
    if isfield(log, name)
        value = log.(name);
        return;
    end
end
end

function params = applyDefaults(params)
if nargin < 1 || isempty(params)
    params = struct();
end

defaults = struct(...
    'fs', [], ...
    'windowSec', 2.0, ...
    'overlapFrac', 0.5, ...
    'nfft', [], ...
    'detrend', true, ...
    'tWindow', [], ...
    'cutoffsHz', [20 30 50], ...
    'bandLimitHz', [0 100]);

fields = fieldnames(defaults);
for idx = 1:numel(fields)
    field = fields{idx};
    if ~isfield(params, field) || isempty(params.(field))
        params.(field) = defaults.(field);
    end
end

end
