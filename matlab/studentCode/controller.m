function u = controller(t, s, pidParams)
%CONTROLLER produces control inputs
%
%   This function implements a PD / PID controller that produces thrust and
%   desired orientation inputs. The return value is a 2-by-1 vector of the
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

