function sT = trajCircle(t, s, p, r, tEnd)
%TRAJLINE Generate circular path following trajectory
%
%   As its name suggests, this trajectory generator should produce a
%   circular trajectory.
%
%   The inputs are
%   t    : time stamp
%   s    : quad. state vector. This has the same structure as 
%          'getStateVector' function's return value.
%   p    : center of circle, 2-by-1 vector in the form [x; y]
%   r    : radius of circle, a scalar value
%   tEnd : time stamp by which the robot should complete the parkour
%
%   This function should return a 9-by-1 column vector with structure
%     sT = [x, y, th, xdot, ydoy, thdot, xddot, yddot, thddot]'
%   where 'dot' and 'ddot' refer to time derivative once and twice
%   respectively.
%

assert(isscalar(t));
assert(all(size(s) == [8, 1]));
assert(all(size(p) == [2, 1]));
assert(isscalar(r));
assert(isscalar(tEnd));

sT = zeros(9, 1);


