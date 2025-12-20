function [trajHandle, params] = trajPresetDiamond()
%TRAJPRESETDIAMOND Sample parameters for the diamond trajectory generator.
%
%   Returns a handle to trajDiamond plus a struct with four corner points and
%   a desired completion time. The fields align with the arguments expected by
%   trajDiamond.

trajHandle = @trajDiamond;
params.p0  = [0.0; 0.0];
params.p1  = [0.5; 0.5];
params.p2  = [0.0; 1.0];
params.p3  = [-0.5; 0.5];
params.tEnd = 10.0;
end
