close all; clear all; clear global;
addpath('./core');
addpath('./utils');
addpath('./scenarios');

addpath('./soln');

% Pick which scenario to run. If no overrides are provided, the default
% line trajectory with the reference LQR controller will be used.
activeScenario = 'line-default';

scenario = chooseScenario(activeScenario);

initialize();
setSolverPreset('balanced', 'ode45');
setScenario(scenario);
respawn();

setTrajectoryGenerator(scenario.trajHandle, scenario.trajParams);
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

summarizeRun();

runPsdReport();
