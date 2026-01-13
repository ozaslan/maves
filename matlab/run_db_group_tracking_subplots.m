%RUN_DB_GROUP_TRACKING_SUBPLOTS  Plot tracking errors for multiple filter groups.
%   Edit the filterGroups block below to define multiple selections, then run
%   this script to plot tracking error subplots for each group.

close all

%% Parameter block (edit these)
% Default database path if left empty.
databaseFile = '';

% Base filters applied to all groups (leave empty to ignore).
runIndices = [];
scenarioNames = {};
trajectoryTypes = {'line'};
trajectoryProfiles = {};
controllerTypes = {};
controllerProfiles = {};
solverPresets = {'balanced'};

% Define multiple groups of filters to plot on separate subplots.
% Groups inherit any filter fields not explicitly provided from the base
% filters above.
filterGroups = {
    struct( ...
        'controllerProfiles', {'default'}, ...
        'controllerTypes', {'pid'}, ...
        'title', 'Line PID - Default')
    struct( ...
        'controllerProfiles', {'aggressive'}, ...
        'controllerTypes', {'pid'}, ...
        'title', 'Line PID - Aggressive')
    struct( ...
        'controllerProfiles', {'default'}, ...
        'controllerTypes', {'lqr'}, ...
        'title', 'Line LQR - Default')
    struct( ...
        'controllerProfiles', {'aggressive'}, ...
        'controllerTypes', {'lqr'}, ...
        'title', 'Line LQR - Aggressive')
    };

showLegend = true;

%% Build options and call the helper
baseFilters = struct();
baseFilters.runIndices = runIndices;
baseFilters.scenarioNames = scenarioNames;
baseFilters.trajectoryTypes = trajectoryTypes;
baseFilters.trajectoryProfiles = trajectoryProfiles;
baseFilters.controllerTypes = controllerTypes;
baseFilters.controllerProfiles = controllerProfiles;
baseFilters.solverPresets = solverPresets;

for idx = 1:numel(filterGroups)
    filterGroups{idx} = mergeFilterGroup(baseFilters, filterGroups{idx});
end

args = { ...
    'showLegend', showLegend ...
    };

[~, metrics] = plotRunGroupTrackingSubplotsFromDatabase(databaseFile, filterGroups, args{:});

% Synchronize axis limits across all subplots.
globalXLim = [inf, -inf];
globalYLim = [inf, -inf];
for idx = 1:numel(metrics)
    series = metrics(idx).trackingError;
    for jdx = 1:numel(series)
        if ~isempty(series(jdx).t)
            globalXLim(1) = min(globalXLim(1), min(series(jdx).t));
            globalXLim(2) = max(globalXLim(2), max(series(jdx).t));
        end
        if ~isempty(series(jdx).error)
            globalYLim(1) = min(globalYLim(1), min(series(jdx).error));
            globalYLim(2) = max(globalYLim(2), max(series(jdx).error));
        end
    end
end

if all(isfinite(globalXLim)) && all(isfinite(globalYLim)) ...
        && globalXLim(1) < globalXLim(2) && globalYLim(1) < globalYLim(2)
    globalYLim(1) = min(globalYLim(1), -0.05);
    axesHandles = findall(gcf, 'Type', 'Axes');
    for idx = 1:numel(axesHandles)
        xlim(axesHandles(idx), globalXLim);
        ylim(axesHandles(idx), globalYLim);
    end
end

fig = gcf;
fig.Units = 'inches';
fig.Position = [1, 1, 12, 8];
fig.PaperPositionMode = 'auto';

legendExplanation = buildLegendExplanation();
disp("Legend abbreviations:");
disp(legendExplanation);

outputDir = fullfile(fileparts(mfilename('fullpath')), 'figures');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end
baseName = fullfile(outputDir, 'db_group_tracking_subplots');
saveas(fig, baseName + ".fig");
exportgraphics(fig, baseName + ".png", 'Resolution', 300);
exportgraphics(fig, baseName + ".pdf");

function merged = mergeFilterGroup(baseFilters, groupFilters)
merged = baseFilters;
if isempty(groupFilters)
    return;
end
fields = fieldnames(groupFilters);
for idx = 1:numel(fields)
    fieldName = fields{idx};
    merged.(fieldName) = groupFilters.(fieldName);
end
end

function explanation = buildLegendExplanation()
abbrevs = {
    "LN", "Line trajectory"
    "CIR", "Circle trajectory"
    "DIA", "Diamond trajectory"
    "PID", "Proportional-Integral-Derivative controller"
    "LQR", "Linear Quadratic Regulator controller"
    "MPC", "Model Predictive Control controller"
    "FST", "Fast solver preset"
    "BAL", "Balanced solver preset"
    "ACC", "Accurate solver preset"
    };

lines = strings(size(abbrevs, 1), 1);
for idx = 1:size(abbrevs, 1)
    lines(idx) = abbrevs{idx, 1} + ": " + abbrevs{idx, 2};
end
explanation = strjoin(lines, " | ");
end
