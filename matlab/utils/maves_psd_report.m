function results = maves_psd_report(log, params)
%MAVES_PSD_REPORT  Generate PSD plots and control-effort metrics for MAVES.
%   RESULTS = MAVES_PSD_REPORT(LOG, PARAMS) computes motor/aggregate PSDs,
%   plots them, and returns metrics that quantify high-frequency thrust
%   fluctuations used to characterize control effort in MAVES.

if nargin < 2 || isempty(params)
    params = struct();
end

psdData = maves_psd_compute(log, params);
metrics = maves_control_effort_metrics(psdData, params);

plotParams = params;
if isfield(params, 'plot')
    plotParams = mergeStructs(plotParams, params.plot);
end
figs = maves_psd_plot(psdData, plotParams);

results = struct('psd', psdData, 'metrics', metrics, 'figs', figs);

if isfield(params, 'outputCsv') && ~isempty(params.outputCsv) && ~isempty(metrics)
    writetable(metrics, params.outputCsv);
end

end

function out = mergeStructs(base, extra)
out = base;
fields = fieldnames(extra);
for idx = 1:numel(fields)
    out.(fields{idx}) = extra.(fields{idx});
end
end
