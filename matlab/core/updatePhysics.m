function [s, stamp] = updatePhysics()
%UPDATEPHYSICS   This function runs EOMs and low-level controller
%
%   This function retrieves controller and trajectory generator handles
%   from the simulator database, generates next trajectory point and
%   control input. Then runs a solver (ode45) for (1 / freq) seconds. The
%   solver executes the ridig-body dynamics, motor dynamics, and low-level
%   attitude controller. At the end of the iteration, it saves the results
%   of solver to simulator database (such as most recent quadcopter state
%   and trajectory point).
%
%   If t = 0, the state of the robot is set equal to trajectory point a 
%   t = 0. This way the quadcopter is always spawm at a state specified by
%   the trajectory generator.
%
%   The outpus are state vector 's' and current time stamp 'stamp'.

[~, prd] = getSimFrequency(); % Get sim. period
global state;

t0  = getStamp(); % Get current time stamp. 
                  % This becomes the starting time of ode45
tf  = t0 + prd;   % Calculate the ode45 end time
s   = getStateVector(); % Get state as vector
sT  = evalTrajectory(t0, s); % Get traj. point as vector
u   = evalControl(t0, s);    % Evaluate the control input

if t0 == 0 % The quadcopter is spawn at trajectory point at t = 0
    s = [sT(1:2); zeros(6, 1)]; % construct quad state from reference traj.
    updateState(t0, s);         % This overwrites the quad. state
    appendTrajPoint(t0, sT(:)); % Record the commanded trajectory hist. of quad.
end

% Configure the solve and run it for [t0, tf] time span.
opt = odeset('RelTol', 1e-5, 'Stats','off');
eom = @(t, s) attitudeControl(t, s, u);
[ts, ss] = ode45(eom, [t0, tf], s, opt);

appendTrajPoint(tf, sT);           % Record quad. state hist.
updateState(ts(end), ss(end, :)'); % Update quad. state with ode45 result.

if isfield(state.qcopter, 'cmd') && ...
        isfield(state.qcopter.cmd, 'stamp') && ...
        ~isempty(state.qcopter.cmd.stamp)
    cmd = state.qcopter.cmd;
    if ~isfield(cmd, 'thDes') || isempty(cmd.thDes)
        cmd.thDes = NaN;
    end
    if ~isfield(cmd, 'thDotDes') || isempty(cmd.thDotDes)
        cmd.thDotDes = NaN;
    end
    if ~isfield(cmd, 'forces') || isempty(cmd.forces)
        cmd.forces = [NaN; NaN];
    end
    state.qcopter.cmdHist = [state.qcopter.cmdHist, ...
        [cmd.stamp; cmd.thDes; cmd.thDotDes; cmd.forces(:)]];
end

stamp = ts(end);

assert(stamp == getStamp());



