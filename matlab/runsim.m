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

% Optional PSD-based control effort analysis (motor thrust fluctuations).
if exist('maves_psd_report', 'file') == 2
    try
        global state;
        psdParams = struct( ...
            'tWindow', [], ...
            'cutoffsHz', [20 30 50], ...
            'bandLimitHz', [0 100], ...
            'outputDir', fullfile(pwd, 'psd_outputs'), ...
            'outputCsv', fullfile(pwd, 'psd_outputs', 'metrics_single.csv'));
        maves_psd_report(state.qcopter, psdParams);
    catch psdErr
        warning('PSD report skipped: %s', psdErr.message);
    end
end
