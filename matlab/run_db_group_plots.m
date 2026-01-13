%RUN_DB_GROUP_PLOTS  Example driver for plotting grouped database runs.
%   Edit the parameter block below to select a subset of runs, then run
%   this script to plot tracking errors, control effort, and RMSE for all
%   matching runs on a shared figure.

close all

%% Parameter block (edit these)
% Default database path if left empty.
databaseFile = '';

% Use specific run indices instead of matching filters.
runIndices = [];

% Filters (leave empty to ignore).
scenarioNames = {};
trajectoryTypes = {'line'};
trajectoryProfiles = {};
controllerTypes = {'lqr'};
controllerProfiles = {};
solverPresets = {'balanced', 'accurate'};

showLegend = true;

%% Build options and call the helper
args = { ...
    'runIndices', runIndices, ...
    'scenarioNames', scenarioNames, ...
    'trajectoryTypes', trajectoryTypes, ...
    'trajectoryProfiles', trajectoryProfiles, ...
    'controllerTypes', controllerTypes, ...
    'controllerProfiles', controllerProfiles, ...
    'solverPresets', solverPresets, ...
    'showLegend', showLegend ...
    };

plotRunGroupFromDatabase(databaseFile, args{:});
