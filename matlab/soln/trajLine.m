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

margin = 0.2;

if t < tEnd
    u = (posEnd - posStart) / tEnd;
    sT(1:2) = t * u + posStart;
    if t < margin * tEnd
        sT(4:5) = u * t / (margin * tEnd);
    elseif t > (1 - margin) * tEnd
        sT(4:5) = u * (tEnd - t) / (margin * tEnd);
    else
        sT(4:5) = u;
    end
else
    sT(1:2) = posEnd;
    sT(4:5) = 0;
end

sT(3)   = 0;
sT(6:9) = 0;



