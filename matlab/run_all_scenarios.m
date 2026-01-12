close all; clear all; clear global;
addpath('./core');
addpath('./utils');
addpath('./scenarios');
addpath('./soln');

scenarioNames = { ...
    'hover-default', ...
    'hover-offset', ...
    'line-default', ...
    'line-short', ...
    'line-long', ...
    'diamond-compact', ...
    'diamond-stretched', ...
    'circle-wide', ...
    'circle-tight' ...
    };

outputDir = fullfile(pwd, 'database');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end
databaseFile = fullfile(outputDir, 'scenario_runs.mat');

database = struct();
database.generatedAt = datetime('now');
database.runs = repmat(struct( ...
    'scenarioName', '', ...
    'scenario', struct(), ...
    'metrics', struct(), ...
    'log', struct(), ...
    'sim', struct(), ...
    'wallTime', NaN), numel(scenarioNames), 1);

for idx = 1:numel(scenarioNames)
    scenario = chooseScenario(scenarioNames{idx}, ...
        'visualizationMode', 'deferred', ...
        'captureMode', 'none');

    initialize();
    global params;
    global state;
    setScenario(scenario);

    params.qcopter.visual.plotFreq = 0;
    params.qcopter.visual.plotTraj = false;
    initPlots();

    respawn();
    setTrajectoryGenerator(scenario.trajHandle, scenario.trajParams);
    setController(scenario.controllerHandle, scenario.controllerParams);
    setVisualizationMode('deferred');
    setCaptureMode('none');

    while checkStatus()
        updatePhysics();
        sleep();
    end

    metrics = summarizeRun('showPlots', false, 'showTable', false);

    database.runs(idx).scenarioName = scenario.name;
    database.runs(idx).scenario = scenario;
    database.runs(idx).metrics = metrics;
    database.runs(idx).log = state.qcopter;
    database.runs(idx).sim = state.sim;
    database.runs(idx).wallTime = metrics.totalWallTime;
end

save(databaseFile, 'database');
fprintf('Saved scenario database to: %s\n', databaseFile);
