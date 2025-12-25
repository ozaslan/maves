close all; clear all; clear global;
addpath('./core');
addpath('./utils');
addpath('./scenarios');

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

% Pick which scenario to run. If no overrides are provided, the default
% line trajectory with the reference LQR controller will be used.
activeScenario = 'line-default';

scenario = chooseScenario(activeScenario);

initialize();
respawn();

registerTrajectory(scenario.trajHandle, scenario.trajParams);
setController(scenario.controllerHandle, scenario.controllerParams);
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
