function sT = trajLine(t, s, posStart, posEnd, tEnd)
%TRAJLINE Generate line following trajectory
%
%   As its name suggests, this trajectory generator should produce a linear
%   trajectory. 
%
%   The inputs are
%   t : time stamp
%   s : quad. state vector. This has the same structure as 'getStateVector'
%       function's return value.
%   posStart : start position. This is a 2-by-1 vector of the form [x; y]
%   posEnd   : end position. This is a 2-by-1 vector of the form [x; y]
%   tEnd     : time stamp by which the robot should arrive at posEnd
%
%   This function should return a column vector with structure
%     sT = [x, y, th, xdot, ydoy, thdot, xddot, yddot, thddot]'
%   where 'dot' and 'ddot' refer to time derivative once and twice
%   respectively.
%

assert(isscalar(t));
assert(all(size(s) == [8, 1]));
assert(all(size(posStart) == [2, 1]));
assert(all(size(posEnd) == [2, 1]));
assert(isscalar(tEnd));

sT = zeros(9, 1); 