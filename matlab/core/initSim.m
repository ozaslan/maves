function initSim()

global params;
global state;

previousScenario = [];
if isstruct(state) && isfield(state, 'scenario')
    previousScenario = state.scenario;
end

state = [];

state.sim.wallStart    = tic;
state.sim.wallStamp    = tic;
state.sim.wallTime     = NaN;
state.sim.stamp        = 0;
state.sim.step         = 0;
if isfield(params, 'sim') && isfield(params.sim, 'solver')
    state.sim.solver = params.sim.solver;
    solverCfg = params.sim.solver;
    solverMethod = solverCfg.method;
    solverRelTol = solverCfg.relTol;
    solverAbsTol = solverCfg.absTol;
    state.sim.solverHandle = str2func(solverMethod);
    state.sim.solverOptions = odeset('RelTol', solverRelTol, ...
        'AbsTol', solverAbsTol, 'Stats', 'off');
end
state.qcopter.pose     = [0; 0; 0];
state.qcopter.vel      = [0; 0; 0];
state.qcopter.w        = [1000; 1000];
state.qcopter.traj     = [];
state.qcopter.trajHist = [];
state.qcopter.forces   = [];
state.qcopter.cmdHist  = [];
state.qcopter.cmd      = struct('stamp', [], ...
                                'thDes', [], ...
                                'thDotDes', [], ...
                                'forces', []);

if ~isempty(previousScenario)
    state.scenario = previousScenario;
end
