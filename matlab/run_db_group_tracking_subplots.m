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
controllerTypes = {'lqr'};
controllerProfiles = {};
solverPresets = {};

% Define multiple groups of filters to plot on separate subplots.
% Groups inherit any filter fields not explicitly provided from the base
% filters above.
filterGroups = {
    struct( ...
        'solverPresets', {'balanced'}, ...
        'title', 'Line LQR - Balanced')
    struct( ...
        'solverPresets', {'accurate'}, ...
        'title', 'Line LQR - Accurate')
    };

showLegend = true;

%% Build options and call the helper
baseFilters = struct( ...
    'runIndices', runIndices, ...
    'scenarioNames', scenarioNames, ...
    'trajectoryTypes', trajectoryTypes, ...
    'trajectoryProfiles', trajectoryProfiles, ...
    'controllerTypes', controllerTypes, ...
    'controllerProfiles', controllerProfiles, ...
    'solverPresets', solverPresets);

for idx = 1:numel(filterGroups)
    filterGroups{idx} = mergeFilterGroup(baseFilters, filterGroups{idx});
end

args = { ...
    'showLegend', showLegend ...
    };

plotRunGroupTrackingSubplotsFromDatabase(databaseFile, filterGroups, args{:});

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
