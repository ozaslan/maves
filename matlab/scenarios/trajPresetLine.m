function [trajHandle, params] = trajPresetLine()
%TRAJPRESETLINE Sample parameters for the line trajectory generator.
%
%   Returns a handle to trajLine plus a struct with start and end positions
%   along with a desired completion time. The field ordering mirrors the
%   inputs to trajLine.

trajHandle      = @trajLine;
params.posStart = [0.0; 0.0];
params.posEnd   = [0.5; 0.5];
params.tEnd     = 10.0;
end
