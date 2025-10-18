function sT = trajDiamond(t, s, p0, p1, p2, p3, tEnd)
%TRAJDIAMOND Generate diamond following trajectory
%
%   As its name suggests, this trajectory generator should produce a 
%   diamond-shaped trajectory. This consists of 4 linears segments. Hence 
%   it is a good idea to use your 'trajLine' function instead of 
%   implementing this from stracth. 
%
%   The inputs are
%   t    : time stamp
%   s    : quad. state vector. This has the same structure as 'getStateVector'
%          function's return value.
%   p0   : first corner of the diamond
%   p1   : second corner of the diamond
%   p2   : third  corner of the diamond
%   p3   : fourth corner of the diamond
%          All waypoint vectors are of the form [x; y]
%   tEnd : time stamp by which the robot should arrive at p0
%
%   This function should return a column vector with structure
%     sT = [x, y, th, xdot, ydoy, thdot, xddot, yddot, thddot]'
%   where 'dot' and 'ddot' refer to time derivative once and twice
%   respectively.
%

assert(isscalar(t));
assert(all(size(s) == [8, 1]));
assert(all(size(p0) == [2, 1]));
assert(all(size(p1) == [2, 1]));
assert(all(size(p2) == [2, 1]));
assert(all(size(p3) == [2, 1]));
assert(isscalar(tEnd));

sT = zeros(9, 1);


     

