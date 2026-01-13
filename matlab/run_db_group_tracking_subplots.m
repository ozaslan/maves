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
        'controllerTypes', {'pid'})
    struct( ...
        'controllerProfiles', {'aggressive'}, ...
        'controllerTypes', {'pid'})
    struct( ...
        'controllerProfiles', {'default'}, ...
        'controllerTypes', {'lqr'})
    struct( ...
        'controllerProfiles', {'aggressive'}, ...
        'controllerTypes', {'lqr'})
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
    filterGroups{idx}.title = buildGroupTitle(filterGroups{idx});
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
nameSuffix = buildGroupNameSuffix(filterGroups);
baseName = fullfile(outputDir, "db_group_tracking_subplots_" + nameSuffix);
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

function suffix = buildGroupNameSuffix(filterGroups)
titles = strings(1, numel(filterGroups));
for idx = 1:numel(filterGroups)
    if isfield(filterGroups{idx}, 'title') && ~isempty(filterGroups{idx}.title)
        titles(idx) = string(filterGroups{idx}.title);
    else
        titles(idx) = "group" + idx;
    end
end
suffix = sanitizeFilename(strjoin(titles, "__"));
if strlength(suffix) == 0
    suffix = "all_groups";
end
end

function cleaned = sanitizeFilename(rawName)
cleaned = lower(rawName);
cleaned = regexprep(cleaned, "[^a-z0-9]+", "_");
cleaned = regexprep(cleaned, "_+", "_");
cleaned = regexprep(cleaned, "^_|_$", "");
end

function titleText = buildGroupTitle(groupFilters)
trajectoryText = formatTitleList(groupFilters.trajectoryTypes, @toTitleCase, " / ");
controllerText = formatTitleList(groupFilters.controllerTypes, @upper, " / ");
profileText = formatTitleList(groupFilters.controllerProfiles, @toTitleCase, " / ");

titleText = "";
if trajectoryText ~= "" && controllerText ~= ""
    titleText = trajectoryText + " " + controllerText;
elseif trajectoryText ~= ""
    titleText = trajectoryText;
elseif controllerText ~= ""
    titleText = controllerText;
end

if profileText ~= ""
    if titleText ~= ""
        titleText = titleText + " - " + profileText;
    else
        titleText = profileText;
    end
end

if titleText == ""
    titleText = "Tracking Error Group";
end
end

function formatted = formatTitleList(values, formatter, separator)
if isempty(values)
    formatted = "";
    return;
end
values = string(values);
values(values == "") = [];
if isempty(values)
    formatted = "";
    return;
end
formattedValues = strings(size(values));
for idx = 1:numel(values)
    formattedValues(idx) = formatter(values(idx));
end
formatted = strjoin(formattedValues, separator);
end

function titleCase = toTitleCase(value)
value = char(value);
if isempty(value)
    titleCase = "";
    return;
end
value = lower(value);
value(1) = upper(value(1));
titleCase = string(value);
end
