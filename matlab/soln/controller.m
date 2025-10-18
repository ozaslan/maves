function u = controller(t, s, pidParams)
%CONTROLLER produces control inputs
%
%   This function implements a PD / PID controller that produces thrust and
%   desired orientation inputs. The return values is a 2-by-1 vector of the
%   form u = [thrust; thdes].  The inputs are
%   t : current time stamp
%   s : state vector. This has the same form as the return value of
%       'getStateVector()' function.
%   pidParams : 3-by-1 vector containing the proportional, integral and
%       derivative gains.  An optional fourth element specifies the maximum
%       magnitude of the integral term for anti-windup.  The parameter is
%       supplied when registering the controller via setController().
%
%   You can use the helper function under 'utils' directory such as
%   'getG()', 'getInertia()', 'evalTrajectory()' etc.

assert(isscalar(t));
assert(all(size(s) == [8, 1]));

if nargin < 3
    error(['PID parameters must be supplied when registering the ', ...
        'controller using setController().']);
end

pidParams = pidParams(:);
assert(numel(pidParams) == 3 || numel(pidParams) == 4, ...
    'pidParams must contain P, I, D gains and an optional integral limit.');

u = zeros(2, 1);

kp = pidParams(1);
ki = pidParams(2);
kd = pidParams(3);

if numel(pidParams) >= 4
    integral_limit = pidParams(4);
else
    integral_limit = 0.5;
end

persistent integralError last_t
if isempty(integralError)
    integralError = zeros(2, 1);
    last_t = t;
end

dt = t - last_t;
last_t = t;

g = getG();
[m, ~] = getInertia();

sT    = evalTrajectory(t, s);
posErr = sT(1:2) - s(1:2);
velErr = sT(4:5) - s(4:5);

if dt > 0
    integralError = integralError + posErr * dt;
end

if ~isempty(integral_limit) && isfinite(integral_limit)
    integral_limit = abs(integral_limit);
    integralError = max(min(integralError, integral_limit), -integral_limit);
end

rddot = sT(7:8) + kd * velErr + kp * posErr + ki * integralError;

th = rddot(1) / -g;
F  = m * (rddot(2) + g);

u = [F; th];

