%RUN_DB_PLOTS  Example driver for plotting runs from the scenario database.
%   Edit the parameter block below to switch which run is loaded and
%   plotted. Uncomment the runIndex option to pick a specific stored run.

close all

%% Parameter block (edit these)
% Default database path if left empty.
databaseFile = '';

% Use a specific run index instead of matching scenario/controller fields.
useRunIndex = false;
runIndex = 1;

% Match the same parameters you would pass to runsim/chooseScenario.
scenarioName = 'diamond-compact';
controllerType = 'pid';
controllerProfile = 'default';
solverPreset = 'accurate';

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

%% Save figures with descriptive names
if useRunIndex
    baseName = sprintf('dbplot_run_%d', runIndex);
else
    baseName = sprintf('dbplot_%s_%s_%s_%s', ...
        scenarioName, controllerType, controllerProfile, solverPreset);
end
baseName = regexprep(baseName, '[^A-Za-z0-9_-]', '-');

figHandles = findall(0, 'Type', 'figure');
for figIndex = 1:numel(figHandles)
    figName = sprintf('%s_fig%02d', baseName, figIndex);
    savefig(figHandles(figIndex), [figName '.fig']);
    saveas(figHandles(figIndex), [figName '.png']);
    saveas(figHandles(figIndex), [figName '.pdf']);
end
