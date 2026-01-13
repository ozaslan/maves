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

% Plot toggles
showArena = true;
showTelemetry = true;
showSummaryPlots = true;
showSummaryTable = true;
runPsdReport = false;

%% Build options and call the helper
opts = struct();
opts.showArena = showArena;
opts.showTelemetry = showTelemetry;
opts.showPlots = showSummaryPlots;
opts.showTable = showSummaryTable;
opts.runPsdReport = runPsdReport;

if useRunIndex
    opts.runIndex = runIndex;
else
    opts.scenarioName = scenarioName;
    opts.controllerType = controllerType;
    opts.controllerProfile = controllerProfile;
end

plotRunFromDatabase(databaseFile, opts);
