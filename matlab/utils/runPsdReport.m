function runPsdReport()
%RUNPSDREPORT Optionally run the PSD control-effort report.

if exist('maves_psd_report', 'file') ~= 2
    return;
end

try
    global state;
    psdParams = struct( ...
        'tWindow', [], ...
        'cutoffsHz', [10 25 40], ...
        'bandLimitHz', [0 100], ...
        'outputDir', fullfile(pwd, 'psd_outputs'), ...
        'outputCsv', fullfile(pwd, 'psd_outputs', 'metrics_single.csv'));
    maves_psd_report(state.qcopter, psdParams);
catch psdErr
    warning('PSD report skipped: %s', psdErr.message);
end

end
