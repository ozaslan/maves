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

controllerTypes = {'pid', 'lqr'};
controllerProfiles = {'default', 'aggressive'};
solverPresets = {'fast', 'balanced', 'accurate'};
visualsEnabled = false;

outputDir = fullfile(pwd, 'database');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end
databaseFile = fullfile(outputDir, 'scenario_runs.mat');

database = struct();
database.generatedAt = datetime('now');
runCount = numel(scenarioNames) * numel(controllerTypes) * numel(controllerProfiles) ...
    * numel(solverPresets);
database.runs = repmat(struct( ...
    'scenarioName', '', ...
    'solverPreset', '', ...
    'scenario', struct(), ...
    'metrics', struct(), ...
    'log', struct(), ...
    'sim', struct(), ...
    'wallTime', NaN), runCount, 1);

runIndex = 1;
for idx = 1:numel(scenarioNames)
    for controllerIdx = 1:numel(controllerTypes)
        for profileIdx = 1:numel(controllerProfiles)
            for presetIdx = 1:numel(solverPresets)
                scenario = chooseScenario(scenarioNames{idx}, ...
                    'controllerType', controllerTypes{controllerIdx}, ...
                    'controllerProfile', controllerProfiles{profileIdx}, ...
                    'visualizationMode', 'deferred', ...
                    'captureMode', 'none');

                initialize('visualsEnabled', visualsEnabled);
                setSolverPreset(solverPresets{presetIdx}, 'ode45');
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

                database.runs(runIndex).scenarioName = scenario.name;
                database.runs(runIndex).solverPreset = solverPresets{presetIdx};
                database.runs(runIndex).scenario = scenario;
                database.runs(runIndex).metrics = metrics;
                database.runs(runIndex).log = state.qcopter;
                database.runs(runIndex).sim = state.sim;
                database.runs(runIndex).wallTime = metrics.totalWallTime;
                runIndex = runIndex + 1;
            end
        end
    end
end

save(databaseFile, 'database');
fprintf('Saved scenario database to: %s\n', databaseFile);
printScenarioDatabaseTable(databaseFile);
