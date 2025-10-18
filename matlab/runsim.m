close all; clear all; clear global;
addpath('./core');
addpath('./utils');

% Exactly one solution directory should be active at a time so that the
% simulator can locate the corresponding controller and trajectory
% generators.  Select the desired submission by setting the label below.
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

initialize();
respawn();

setArena("empty");
obs = getObstacles();

%% Sample Waypoints
% Sample waypoints. See how each trajectory generater is registered.
% The number of arguments for each type of generator is different. Details
% about input arguments are at the preamble of the corresponding script
% file. You can keep these as they are or try different way-points. However
% your codes will be tested against random way-points chosen by the
% instructor.

p0 = [ 0; 0];
p1 = [ 1; 1] / 2;
p2 = [ 0; 2] / 2;
p3 = [-1; 1] / 2;
tF = 10;  % Final time stamp. You quad. should hover in-place at the final 
          % position for t > tF.
r  = 0.5; % Circular trajectory radius

%% Trajectory Generator Inventory
% Only one the following lines will be uncommented for testing. The
% arguments are correct and you are expected to take these sample lines as
% instruction in your development.

% setTrajectoryGenerator(@trajHover, p0);
% setTrajectoryGenerator(@trajLine, p0, p1, tF);
% setTrajectoryGenerator(@trajDiamond, p0, p1, p2, p3, tF);
setTrajectoryGenerator(@trajCircle, p0, r, tF);


%% Control
% Register the controller and provide the PID gains (and optional integral
% limit) that should be used for the simulation.

pidGains = [3; 1.0; 2];
integralLimit = 5.0;

setController(@controller, [pidGains; integralLimit]);

%% Visualization Mode
% Choose how plots are updated during the simulation. Use 'live' to maintain
% the previous behaviour with real-time updates, or switch to 'deferred' to
% run the dynamics as fast as possible and only render the final plots once
% the simulation is complete.
visualizationMode = 'live';  % Options: 'live', 'deferred'
setVisualizationMode(visualizationMode);

%% Capture Mode
% Choose whether to save the arena visualization to disk. When set to
% 'save', the simulator records an MPEG-4 video while running in live mode
% and exports a PNG image of the final frame when running in deferred mode.
captureMode = 'save';  % Options: 'save', 'none'
setCaptureMode(captureMode);

%% Main Loop
% This loop continues until either your quadcopter arrives at the final
% position of the corresponding trajectory generator and hovers in place,
% or if it diverges. Divergance is detected when the position of the
% quadcopter is outside the arena. The limits of the arena get be retrieved
% using 'getArenaLimits()'. If you trajectory generator goes beyond those
% limits, you code will be deemed as unsuccessful.
while checkStatus()
    updatePhysics();
    updateVisuals();
    sleep();
end

fprintf('Simulation Stopped!\n');
updateVisuals(true);
drawnow();


