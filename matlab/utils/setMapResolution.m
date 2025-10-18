function res = setMapResolution(res)
%SETMAPRESOLUTION set the resolution of the occupancy grid map
%
%   This function sets the cell size in meters. This has to be a positive
%   value. 

if res < 0
    error("Cell size must be a positive value");
end

global params;

params.arena.resolution = res;


