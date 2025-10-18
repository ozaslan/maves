function sdot = attitudeControl(t, s, u)
%EOM This implements the low-level attitude control
%   
%   This implements attitude PD control. The input are 
%   t : time stamp
%   s : quad. state vector (same as returned by 'getStateVector')
%   u : control inputs of the form [F, thDes]
%
global params;
global state;

assert(isscalar(t));
assert(all(size(s) == [8, 1]));
assert(all(size(u) == [2, 1]));

kF   = params.qcopter.phys.kF;   % Propeller model
kD   = params.qcopter.phys.kDth; % Att. control D gain
kP   = params.qcopter.phys.kPth; % Att. control P gain
ell  = params.qcopter.visual.boomLength; % Boom length
wMax = params.qcopter.phys.wMax;    % Max motor rpm.
tMax = params.qcopter.phys.maxTilt; % Max tilt angle

th    = s(3); % Current tilt
thDot = s(6); % Current tilt rate

fDes     = u(1); % Commanded thrust
thDes    = u(2); % Commanded tilt
thDotDes = 0;

% Clamp the commanded tilt to limits
thDes = min(thDes,  tMax);
thDes = max(thDes, -tMax);

% PD controller law
M  = kP * (thDes - th) + kD * (thDotDes - thDot);
% We command forces, not moments. Find the forces that would yield the
% required moment while satisfying the command total thrust
F1 = fDes / 2 - M / ell;
F2 = fDes / 2 + M / ell;

% Transform forces into RPMs and then impose motor speed limit and positive
% RPM requirements.
w1des = sign(F1) * sqrt(abs(F1) / kF);
w2des = sign(F2) * sqrt(abs(F2) / kF);
w1des = min(max(w1des, 0), wMax);
w2des = min(max(w2des, 0), wMax);
wDes  = [w1des; w2des];

state.qcopter.cmd.stamp    = t;
state.qcopter.cmd.thDes    = thDes;
state.qcopter.cmd.thDotDes = thDotDes;
state.qcopter.cmd.forces   = kF * (wDes .^ 2);

% Execute that lower-level rigid-body and motor dynamics.
sdot = eomMotorAndRigidBody(t, s, wDes);

