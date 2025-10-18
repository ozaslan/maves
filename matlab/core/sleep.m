function dur = sleep()
%SLEEP This function puts sim. to halting sleep.
%
%   This function puts the simulator into sleep such that the update rate
%   matches the simulator frequency given in the parameters. If the solver
%   and plotting functions already take long time, this function has no
%   effect. Otherwise this slows down the plotting preventing it to run
%   too fast to follow during debugging and testing.

global params;
global state;

stamp  = getStamp();

runMode = 'live';
if isfield(params, 'sim') && isfield(params.sim, 'runMode') && ...
        ~isempty(params.sim.runMode)
    runMode = params.sim.runMode;
end
isLiveMode = strcmpi(runMode, 'live');

if isLiveMode
    fprintf('Time : %f\n', stamp);
end

wStamp = state.sim.wallStamp;
period = 1 / getSimFrequency();

dur = max(0, period - toc(wStamp));

if isLiveMode && dur > 0
    pause(dur);
end

state.sim.step      = state.sim.step + 1;
state.sim.wallStamp = tic;


