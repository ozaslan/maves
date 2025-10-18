function stat = checkStatus()
%CHECKSTATUS  Checks the health of simulator
%
%   This function check a number of conditions that need to be satisfied in
%   order the simulator to proceed. These include the following
%   - Check if the robot is inside the arena
%   - Check if the robot collides with an object
%   - ...
%
%   If at least one condition fails, this function returns false, and true
%   otherwise.

global params;
global state;

stat = true;

pose  = getPose();
stamp = getStamp();

limits = getArenaLimits();

if any(pose(1:2) < limits(:, 1)) || any(pose(1:2) > limits(:, 2))
    fprintf('Your quad. is outside the arena limits.\n');
    stat = false;
    return
end

if size(state.qcopter.traj, 2) > 100
    mask   = (stamp - state.qcopter.traj(1, :)) < 1;
    traj   = state.qcopter.traj(5:7, mask);
    motion = std(traj, 0, 2);
    
    s      = getStateVector();
    sT     = params.trajGen(1e10, s);
    dPos   = norm(s(1:2) - sT(1:2));
    
    if all(motion < 0.005) && dPos < 0.01
        fprintf('Good job!\n');
        stat = false;
        return;
    end
end






