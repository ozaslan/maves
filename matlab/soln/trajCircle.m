function sT = trajCircle(t, s, p, r, startAngle, tEnd)
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
%   startAngle : starting angle (radians) along the circle
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
if nargin < 6
    tEnd = startAngle;
    startAngle = 0;
end

assert(isscalar(startAngle));
assert(isscalar(tEnd));

sT = zeros(9, 1);

dth = 2 * pi / tEnd;

if t > tEnd
    t = tEnd;
end

theta = startAngle + t * dth;

sT(1) = r * cos(theta) + p(1);
sT(2) = r * sin(theta) + p(2);
sT(3) = 0;

if t < tEnd
    sT(4) = -dth * r * sin(theta);
    sT(5) =  dth * r * cos(theta);
    sT(6) = 0;
    sT(7) = -dth^2 * r * cos(theta);
    sT(8) = -dth^2 * r * sin(theta);
    sT(9) = 0;
end




