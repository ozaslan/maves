function sT = trajHover(t, s, r)
%TRAJHOVER Generate hovering trajectory
%
%   As its name suggests, this trajectory generator should produce a goal
%   position equal to the current position of the quadcopter. Also, the
%   goal velocity and orientation have to be zero to achieve hovering in
%   place.
%
%   The inputs are 
%   t : time stamp
%   s : quad. state vector. Ths has the same structure as 'getStateVector' 
%       function's return value.
%   r : position to hover at. r is 2-by-1 and its structure is r = [x; y]
%
%   This function should return a column vector with structure
%     sT = [x, y, th, xdot, ydoy, thdot, xddot, yddot, thddot]'
%   where 'dot' and 'ddot' refer to time derivative once and twice
%   respectively.
%

assert(isscalar(t));
assert(all(size(s) == [8, 1]));
assert(all(size(r) == [2, 1]));

sT = zeros(9, 1);

sT(1:2) = r;
sT(3)   = 0;      % Quad. will be level
sT(4:9) = 0;      % Higher order derivative are zero.
                  % All trajetory states are independent of time

