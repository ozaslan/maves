function ws = getRPMs()
%GETRPMS returns the RPMs of the two propellers
%   
%   Return value is a 2-by-1 vector of RPM values. The first value is the
%   RPM of the left-hand-side motor.

global state;
ws = state.qcopter.w(:);



