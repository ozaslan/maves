function [trajHandle, params] = trajPresetCircle()
%TRAJPRESETCIRCLE Sample parameters for the circle trajectory generator.
%
%   Returns a handle to trajCircle plus a struct that bundles the circle
%   center, radius, starting angle along the curve, and desired completion
%   time. The center, radius, and timing reflect the sample setup in
%   runsim.m.

trajHandle = @trajCircle;
params.center      = [0.0; 0.0];
params.radius      = 0.5;
params.startAngle  = 0.0;  % radians
params.tEnd        = 10.0;
end
