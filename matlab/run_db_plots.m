%RUN_DB_PLOTS  Example driver for plotting runs from the scenario database.
%   Edit the parameter block below to switch which run is loaded and
%   plotted. Uncomment the runIndex option to pick a specific stored run.

%% Parameter block (edit these)
% Default database path if left empty.
databaseFile = '';

% Use a specific run index instead of matching scenario/controller fields.
useRunIndex = false;
runIndex = 1;

% Match the same parameters you would pass to runsim/chooseScenario.
scenarioName = 'line-default';
controllerType = 'lqr';
controllerProfile = 'default';
solverPreset = 'balanced';

% Plot toggles
showArena = true;
showTelemetry = true;
showSummaryPlots = true;
showSummaryTable = true;
runPsdReport = false;

%% Build options and call the helper
args = { ...
    'showArena', showArena, ...
    'showTelemetry', showTelemetry, ...
    'showPlots', showSummaryPlots, ...
    'showTable', showSummaryTable, ...
    'runPsdReport', runPsdReport ...
    };

if useRunIndex
    args = [args, {'runIndex', runIndex}];
else
    args = [args, { ...
        'scenarioName', scenarioName, ...
        'controllerType', controllerType, ...
        'controllerProfile', controllerProfile, ...
        'solverPreset', solverPreset ...
        }];
end

plotRunFromDatabase(databaseFile, args{:});
