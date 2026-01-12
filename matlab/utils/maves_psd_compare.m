function results = maves_psd_compare(logs, labels, params)
%MAVES_PSD_COMPARE  Compare PSDs across controller tunings.
%   RESULTS = MAVES_PSD_COMPARE(LOGS, LABELS, PARAMS) computes PSDs and
%   metrics for each log, then generates a comparison PSD plot (default
%   signal F1+F2). Intended to highlight higher-frequency thrust activity
%   when gains increase (e.g., 5x PD gains).

if nargin < 3 || isempty(params)
    params = struct();
end

if ~isfield(params, 'comparisonSignal') || isempty(params.comparisonSignal)
    params.comparisonSignal = 'Fsum';
end

if ~isfield(params, 'comparisonSignalLabel') || isempty(params.comparisonSignalLabel)
    params.comparisonSignalLabel = 'F1 + F2';
end

if ~isfield(params, 'savePlots') || isempty(params.savePlots)
    params.savePlots = true;
end

if ~isfield(params, 'outputDir')
    params.outputDir = '';
end

if nargin < 2 || isempty(labels)
    labels = arrayfun(@(i) sprintf('Run %d', i), 1:numel(logs), ...
        'UniformOutput', false);
end

numRuns = numel(logs);
results = repmat(struct('psd', [], 'metrics', []), numRuns, 1);
comparison = repmat(struct('label', '', 'signal', []), numRuns, 1);

for idx = 1:numRuns
    psdData = maves_psd_compute(logs{idx}, params);
    metrics = maves_control_effort_metrics(psdData, params);
    results(idx).psd = psdData;
    results(idx).metrics = metrics;

    if isfield(psdData.signals, params.comparisonSignal)
        comparison(idx).label = labels{idx};
        comparison(idx).signal = psdData.signals.(params.comparisonSignal);
    end
end

plotParams = params;
if isfield(params, 'plot')
    plotParams = mergeStructs(plotParams, params.plot);
end

plotParams.comparisonSignalLabel = params.comparisonSignalLabel;
plotParams.savePlots = params.savePlots;
plotParams.outputDir = params.outputDir;

psdCompare = struct('comparison', comparison);
figs = maves_psd_plot(psdCompare, plotParams);

results(1).comparisonFig = figs.comparison;

if isfield(params, 'outputCsv') && ~isempty(params.outputCsv)
    combined = concatenateMetrics(results, labels);
    writetable(combined, params.outputCsv);
end
end

function combined = concatenateMetrics(results, labels)
combined = table();
for idx = 1:numel(results)
    metrics = results(idx).metrics;
    if isempty(metrics)
        continue;
    end
    metrics.Run = repmat(labels(idx), height(metrics), 1);
    metrics = movevars(metrics, 'Run', 'Before', 1);
    combined = [combined; metrics]; %#ok<AGROW>
end
end

function out = mergeStructs(base, extra)
out = base;
fields = fieldnames(extra);
for idx = 1:numel(fields)
    out.(fields{idx}) = extra.(fields{idx});
end
end
