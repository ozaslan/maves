function path = getArenaPath()
%GETARENAPATH returns the path to arena file
%   This function returns the path to the arena text file. If the path does
%   not exist, the return value is an empty string.

global params;

simRoot = getRootFolder();
path    = append(simRoot, "/arenas/", params.arena.name, ".txt");

file = java.io.File(path);

if ~file.exists()
    path = "";
end
