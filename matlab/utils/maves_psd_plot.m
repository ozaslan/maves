function figs = maves_psd_plot(psdData, params)
%MAVES_PSD_PLOT  Plot PSDs for MAVES motor thrust signals.
%   FIGS = MAVES_PSD_PLOT(PSDDATA, PARAMS) generates paper-ready PSD plots
%   (motor PSDs, aggregate PSD, and comparison plots if provided) that
%   visualize high-frequency control effort consistent with the MAVES paper.

if nargin < 2 || isempty(params)
    params = struct();
end

params = applyPlotDefaults(params);
figs = struct();

if isempty(psdData) || ~isfield(psdData, 'signals')
    warning('maves_psd_plot:MissingData', 'No PSD data supplied for plotting.');
    return;
end

if isfield(psdData, 'comparison') && ~isempty(psdData.comparison)
    figs.comparison = plotComparison(psdData.comparison, params);
    return;
end

figs.motors = plotMotorPsd(psdData, params);
figs.aggregate = plotAggregatePsd(psdData, params);

end

function fig = plotMotorPsd(psdData, params)
signals = psdData.signals;
if ~isfield(signals, 'F1') || ~isfield(signals, 'F2')
    warning('maves_psd_plot:MissingMotors', 'Motor PSD data missing.');
    fig = [];
    return;
end

fig = figure('Name', 'Motor Thrust PSD', 'NumberTitle', 'off');
tiledlayout(1, 1, 'Padding', 'compact', 'TileSpacing', 'compact');
ax = nexttile(1);

plotPsd(ax, signals.F1.f, signals.F1.Pxx, 'F1', params);
hold(ax, 'on');
plotPsd(ax, signals.F2.f, signals.F2.Pxx, 'F2', params);
hold(ax, 'off');

title(ax, 'Motor Thrust PSD (F1, F2)');
xlabel(ax, 'Frequency [Hz]');
ylabel(ax, 'PSD [N^2/Hz]');
grid(ax, 'on');
set(ax, 'FontSize', params.fontSize);
axis(ax, 'tight');
legend(ax, 'show', 'Location', 'best');
applyCutoffs(ax, params.cutoffsHz, params.fontSize);

exportFigure(fig, params, 'motor_psd');
end

function fig = plotAggregatePsd(psdData, params)
signals = psdData.signals;
if ~isfield(signals, 'Fsum') || ~isfield(signals, 'Fn')
    warning('maves_psd_plot:MissingAggregate', 'Aggregate PSD data missing.');
    fig = [];
    return;
end

fig = figure('Name', 'Aggregate Thrust PSD', 'NumberTitle', 'off');
tiledlayout(1, 1, 'Padding', 'compact', 'TileSpacing', 'compact');
ax = nexttile(1);

plotPsd(ax, signals.Fsum.f, signals.Fsum.Pxx, 'F1 + F2', params);
hold(ax, 'on');
plotPsd(ax, signals.Fn.f, signals.Fn.Pxx, 'sqrt(F1^2 + F2^2)', params);
hold(ax, 'off');

title(ax, 'Aggregate Thrust PSD');
xlabel(ax, 'Frequency [Hz]');
ylabel(ax, 'PSD [N^2/Hz]');
grid(ax, 'on');
set(ax, 'FontSize', params.fontSize);
axis(ax, 'tight');
legend(ax, 'show', 'Location', 'best');
applyCutoffs(ax, params.cutoffsHz, params.fontSize);

exportFigure(fig, params, 'aggregate_psd');
end

function fig = plotComparison(comparisonData, params)
fig = figure('Name', 'PSD Comparison', 'NumberTitle', 'off');
tiledlayout(1, 1, 'Padding', 'compact', 'TileSpacing', 'compact');
ax = nexttile(1);
hold(ax, 'on');

for idx = 1:numel(comparisonData)
    entry = comparisonData(idx);
    if ~isfield(entry, 'signal') || isempty(entry.signal)
        continue;
    end
    label = entry.label;
    plotPsd(ax, entry.signal.f, entry.signal.Pxx, label, params);
end
hold(ax, 'off');

title(ax, sprintf('PSD Comparison: %s', params.comparisonSignalLabel));
xlabel(ax, 'Frequency [Hz]');
ylabel(ax, 'PSD [N^2/Hz]');
grid(ax, 'on');
set(ax, 'FontSize', params.fontSize);
axis(ax, 'tight');
legend(ax, 'show', 'Location', 'best');
applyCutoffs(ax, params.cutoffsHz, params.fontSize);

exportFigure(fig, params, 'comparison_psd');
end

function plotPsd(ax, f, Pxx, label, params)
if isempty(f) || isempty(Pxx)
    return;
end

mask = f >= params.bandLimitHz(1) & f <= params.bandLimitHz(2);
f = f(mask);
Pxx = Pxx(mask);

if params.useLogScale
    semilogy(ax, f, Pxx, 'LineWidth', 1.5, 'DisplayName', label);
else
    plot(ax, f, Pxx, 'LineWidth', 1.5, 'DisplayName', label);
end
end

function applyCutoffs(ax, cutoffs, fontSize)
ylims = ylim(ax);
for idx = 1:numel(cutoffs)
    fc = cutoffs(idx);
    line(ax, [fc fc], ylims, 'LineStyle', '--', 'Color', [0.5 0.5 0.5], ...
        'HandleVisibility', 'off');
    text(ax, fc, ylims(2), sprintf(' %g Hz', fc), ...
        'VerticalAlignment', 'top', 'FontSize', max(8, fontSize - 2), ...
        'Color', [0.3 0.3 0.3]);
end
end

function exportFigure(fig, params, stemName)
if ~params.savePlots
    return;
end

if isempty(params.outputDir)
    outputDir = pwd;
else
    outputDir = params.outputDir;
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

pdfFile = fullfile(outputDir, sprintf('%s.pdf', stemName));
pngFile = fullfile(outputDir, sprintf('%s.png', stemName));
exportgraphics(fig, pdfFile, 'ContentType', 'vector');
exportgraphics(fig, pngFile, 'Resolution', 300);
end

function params = applyPlotDefaults(params)
defaults = struct( ...
    'cutoffsHz', [20 30 50], ...
    'bandLimitHz', [0 100], ...
    'useLogScale', true, ...
    'savePlots', true, ...
    'outputDir', '', ...
    'comparisonSignalLabel', 'F1 + F2', ...
    'fontSize', 11);

fields = fieldnames(defaults);
for idx = 1:numel(fields)
    field = fields{idx};
    if ~isfield(params, field) || isempty(params.(field))
        params.(field) = defaults.(field);
    end
end
end
