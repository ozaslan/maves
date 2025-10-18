function sdot = eomMotorAndRigidBody(t, s, wdes)
%EOMLOWLEVEL This implements the lower-level dynamics
%   
%   This implements motor + rigid body dynamics. Inputs are 
%   t    : time stamp
%   s    : quad. state vector (same as returned by 'getStateVector')
%   wdes : desired RPMs for propellers. This has the form [w1des; w2des]
global params;

assert(isscalar(t));
assert(all(size(s) == [8, 1]));
assert(all(size(wdes) == [2, 1]));

g    = params.sim.g; % gravitatinal acceleration
m    = params.qcopter.phys.m; % mass of the quadcopter
I    = params.qcopter.phys.I; % rotational inertia of the quadcopter
kF   = params.qcopter.phys.kF; % propeller RPM-to-force constant
km   = params.qcopter.phys.km; % motor dynamics
ell  = params.qcopter.visual.boomLength; % boom length
wMax = params.qcopter.phys.wMax; % max RPM.

th = s(3); % current tilt angle in radians
w1 = min(max(s(7), 0), wMax); % clamp RPMs to allowable limits
w2 = min(max(s(8), 0), wMax); % 

% Re-calculate forces and moment to execute rigid-body dynamics
F1 = kF * w1^2;
F2 = kF * w2^2;
M  = (F2 - F1) * ell;

% Execute rigid-body and motor dynamics
sdot    = zeros(8, 1); 
sdot(1) = s(4);        % xdot
sdot(2) = s(5);        % ydot
sdot(3) = s(6);        % thdot
sdot(4) = -1 / m * sin(th) * (F1 + F2);     % xddot
sdot(5) =  1 / m * cos(th) * (F1 + F2) - g; % yddot
sdot(6) =  1 / I * M;                       % thddot
sdot(7) = km * (wdes(1) - w1); % first-order motor model
sdot(8) = km * (wdes(2) - w2); % w1dot and w2dot

