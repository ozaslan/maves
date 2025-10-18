function fs = getForces()
%GETFORCES This function returns the forces produced by each motor
%   
%   The return value is a 2-by-1 vector of forces in N.

global params;

ws = getRPMs();
fs = params.qcopter.phys.kF * ws(:).^2;


