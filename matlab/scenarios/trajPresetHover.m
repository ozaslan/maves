function [trajHandle, params] = trajPresetHover()
%TRAJPRESETHOVER Sample hover point used to anchor a hover trajectory.
%
%   Returns a handle to trajHover along with a 2-by-1 position vector that
%   can be passed to setTrajectoryGenerator to command the quadrotor to hold
%   position at that point.

trajHandle = @trajHover;
params     = [0.0; 0.0];
end
