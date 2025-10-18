function initParams()
%SETUPPARAMS  Initializes simulator parameters
%
%   SETUPPARAMS() initialized all the parameters that control the flow of
%   the simulator. These include parameters regarding the dynamics,
%   control, visualization etc. All the parameters are stored in the
%   structure 'params'. This variable is defined as 'global'. Other
%   functions that need to retrieve one or more of the parameters should
%   add 'global params;' at the preeamble of the function body.

global params;

params = []; % Reset to empty structure

%% MISCELLANEOUS
params.closeAllFigures = false;

%% SIMULATOR
params.sim.g       = 9.81;
params.sim.freq    = 50;
params.sim.runMode = 'live';
params.sim.capture = struct( ...
    'mode', 'none', ...
    'timestamp', '', ...
    'videoFile', '', ...
    'imageFile', '', ...
    'outputDir', '', ...
    'writer', [], ...
    'isRecording', false, ...
    'imageSaved', false);

%% MISC PLOTS
params.plots.figIndex = 34;
params.plots.figHandle = [];
params.plots.panelHandle = [];
params.plots.layoutHandle = [];
params.plots.axesHandle = [];
params.plots.axesHandles = [];
params.plots.statusPanelHandle = [];
params.plots.statusTextHandles = struct();

%% ARENA
% Parameters related to the shape of the arena, ie. the 2D rectangular
% region the drone flies.
params.arena.figIndex   = 33;
params.arena.figHandle  = [];
params.arena.axesHandle = [];
params.arena.title      = "Arena";
params.arena.limits     = [[-10; -10], [10; 10]];
params.arena.name       = "arena-00";
params.arena.resolution = 0.05;
params.arena.sizeTextHandle = [];
params.arena.resizeComplete = false;
params.arena.dynamicLimits = [];
params.arena.limitSmoothingAlpha = 0.85;

%% QUADCOPTER VISUALS
% Parameters related to the visual appearance of the quadcopter.
params.qcopter.visual.boomLength    = 0.046; % center to motor in m.
params.qcopter.visual.bodyLength    = 0.020; % center plate width in m.
params.qcopter.visual.bodyHeight    = 0.010; % center height in m.
params.qcopter.visual.propSize      = 0.025; % prop. size in m.
params.qcopter.visual.bodyColor     = 'r';
params.qcopter.visual.propColor     = 'k';
params.qcopter.visual.trajColor     = 'g';
params.qcopter.visual.commandsColor = 'k';
params.qcopter.visual.plotTraj      = true;
params.qcopter.visual.plotFreq      = 10; % 1D plots are drawn once only every plotFreq-th step

%% QUADCOPTER DYNAMICS
% Parameters that affect the dynamics of the quadcopter such as mass,
% rotational inertial, controller parameters etc.
params.qcopter.phys.m    = 0.05;    % mass in kg.
params.qcopter.phys.I    = 1.43e-5; % rot. inertia in kg m^2
params.qcopter.phys.wMax = 2.0e4;    % max rpm
params.qcopter.phys.kF   = 6.11e-8; % rmp-to-force coeff. in N / rpm^2
params.qcopter.phys.km   = 50;     % motor dynamics coeff
params.qcopter.phys.kPth = .90;    % att. ctrl. P coeff
params.qcopter.phys.kDth = .20;  % att. ctrl. D coeff
params.qcopter.phys.maxTilt = deg2rad(25); % max. tilt angle