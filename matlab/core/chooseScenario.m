function scenario = chooseScenario(scenarioName, opts)
%CHOOSESCENARIO Resolve trajectory and controller selections.
%
%   scenario = chooseScenario() returns the default scenario pairing, using
%   the line trajectory with the reference LQR controller and live
%   visualization. Scenario name, controller type, controller parameters,
%   and trajectory presets can be overridden via name/value pairs.
%
%   Available scenario names mirror the legacy catalog:
%       - "hover-default"
%       - "line-default" (default)
%       - "diamond-compact"
%       - "circle-wide"

arguments
    scenarioName (1, :) char = 'line-default'
    opts.controllerType (1, :) char = ''
    opts.controllerProfile (1, :) char = ''
    opts.controllerParams = []
    opts.trajPreset = []
    opts.trajProfile (1, :) char = ''
    opts.trajHandle = []
    opts.trajParams = []
    opts.visualizationMode (1, :) char = ''
    opts.captureMode (1, :) char = ''
end

catalog = defaultCatalog();

scenarioName = lower(scenarioName);
names = {catalog.name};
if ~ismember(scenarioName, names)
    error('Unknown scenario "%s". Choose from: %s', ...
        scenarioName, strjoin(names, ', '));
end

scenario = catalog(strcmp(scenarioName, names));

% Apply overrides when provided.
if ~isempty(opts.controllerType)
    scenario.controllerType = opts.controllerType;
end
if ~isempty(opts.controllerProfile)
    scenario.controllerProfile = opts.controllerProfile;
end
if ~isempty(opts.trajPreset)
    scenario.trajPreset = opts.trajPreset;
end
if ~isempty(opts.trajProfile)
    scenario.trajProfile = opts.trajProfile;
end
if ~isempty(opts.visualizationMode)
    scenario.visualizationMode = opts.visualizationMode;
end
if ~isempty(opts.captureMode)
    scenario.captureMode = opts.captureMode;
end

% Resolve trajectory selection.
if isempty(opts.trajHandle)
    [scenario.trajHandle, scenario.trajParams] = scenario.trajPreset(scenario.trajProfile);
else
    scenario.trajHandle = opts.trajHandle;
    if isempty(opts.trajParams)
        scenario.trajParams = struct();
    else
        scenario.trajParams = opts.trajParams;
    end
end

% Resolve controller selection.
scenario.controllerHandle = controllerHandle(scenario.controllerType);
if isempty(opts.controllerParams)
    scenario.controllerParams = controllerPresets(scenario.controllerType, ...
                                                 scenario.controllerProfile);
else
    scenario.controllerParams = opts.controllerParams;
end

end

function catalog = defaultCatalog()
%DEFAULTCATALOG Baseline scenario catalog bundled with the simulator.

catalog = [ ...
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

