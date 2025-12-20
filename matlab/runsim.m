close all; clear all; clear global;
addpath('./core');
addpath('./utils');

% Exactly one solution directory should be active at a time so that the
% simulator can locate the corresponding controller and trajectory
% generators. Select the desired submission by setting the label below.
% Use 'student' for the starter code provided in this repository.
activeSolution = 'solution';

solutionPaths = {
    'student', './studentCode';
    'solution', './soln';
};

solutionLabels = solutionPaths(:, 1);
if ~ismember(activeSolution, solutionLabels)
    error('Unknown submission "%s". Update activeSubmission to one of: %s', ...
        activeSolution, strjoin(solutionLabels', ', '));
end

for idx = 1:size(solutionPaths, 1)
    solutionDir = solutionPaths{idx, 2};
    if strcmp(solutionPaths{idx, 1}, activeSolution)
        addpath(solutionDir);
    else
        try
            rmpath(solutionDir);
        end
    end
end

% Pick which scenario to run from the catalog defined below. Each entry
% bundles a trajectory preset with its parameters, a controller preset, and
% visualization options.
activeScenario = 'line-default';

scenarios = scenarioCatalog();
scenarioNames = {scenarios.name};
if ~ismember(activeScenario, scenarioNames)
    error('Unknown scenario "%s". Choose from: %s', ...
        activeScenario, strjoin(scenarioNames, ', '));
end

scenario = scenarios(strcmp(activeScenario, scenarioNames));

initialize();
respawn();

configureScenario(scenario);
setVisualizationMode(scenario.visualizationMode);
setCaptureMode(scenario.captureMode);

%% Main Loop
% This loop continues until either your quadcopter arrives at the final
% position of the corresponding trajectory generator and hovers in place,
% or if it diverges.
while checkStatus()
    updatePhysics();
    updateVisuals();
    sleep();
end

fprintf('Simulation Stopped!\n');
updateVisuals(true);
drawnow();

%% Scenario helpers
function scenarios = scenarioCatalog()
%SCENARIOCATALOG Collection of bundled trajectory and controller presets.

scenarios = [ ...
    struct('name', 'hover-default', ...
           'trajPreset', @trajPresetHover, ...
           'trajProfile', 'default', ...
           'controllerType', 'pid', ...
           'controllerProfile', 'default', ...
           'visualizationMode', 'live', ...
           'captureMode', 'save'); ...
    struct('name', 'line-default', ...
           'trajPreset', @trajPresetLine, ...
           'trajProfile', 'default', ...
           'controllerType', 'lqr', ...
           'controllerProfile', 'default', ...
           'visualizationMode', 'live', ...
           'captureMode', 'save'); ...
    struct('name', 'diamond-compact', ...
           'trajPreset', @trajPresetDiamond, ...
           'trajProfile', 'compact', ...
           'controllerType', 'pid', ...
           'controllerProfile', 'aggressive', ...
           'visualizationMode', 'live', ...
           'captureMode', 'save'); ...
    struct('name', 'circle-wide', ...
           'trajPreset', @trajPresetCircle, ...
           'trajProfile', 'wide', ...
           'controllerType', 'lqr', ...
           'controllerProfile', 'aggressive', ...
           'visualizationMode', 'deferred', ...
           'captureMode', 'none') ...
];
end

function configureScenario(scenario)
%CONFIGURESCENARIO Apply the trajectory and controller presets.

trajPreset = scenario.trajPreset;
[trajHandle, trajParams] = trajPreset(scenario.trajProfile);
registerTrajectory(trajHandle, trajParams);

ctrlParams = controllerPresets(scenario.controllerType, ...
                               scenario.controllerProfile);
setController(controllerHandle(scenario.controllerType), ctrlParams);
end

function registerTrajectory(trajHandle, trajParams)
%REGISTERTRAJECTORY Configure the selected trajectory generator.

switch func2str(trajHandle)
    case 'trajHover'
        setTrajectoryGenerator(trajHandle, trajParams);
    case 'trajLine'
        setTrajectoryGenerator(trajHandle, trajParams.posStart, ...
            trajParams.posEnd, trajParams.tEnd);
    case 'trajDiamond'
        setTrajectoryGenerator(trajHandle, trajParams.p0, trajParams.p1, ...
            trajParams.p2, trajParams.p3, trajParams.tEnd);
    case 'trajCircle'
        setTrajectoryGenerator(trajHandle, trajParams.center, ...
            trajParams.radius, trajParams.tEnd);
    otherwise
        error('Unsupported trajectory generator: %s', func2str(trajHandle));
end
end

function handle = controllerHandle(controllerType)
%CONTROLLERHANDLE Map a controller preset name to the implementation handle.

switch lower(controllerType)
    case 'pid'
        handle = @controller;
    case 'lqr'
        handle = @controller_lqr;
    otherwise
        error('Unsupported controller preset "%s".', controllerType);
end
end
