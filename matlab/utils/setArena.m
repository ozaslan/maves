function tf = setArena(aname)
%SETARENANAME sets the arena name
%   This function sets the arena name in the simulator database. The input
%   'aname' must be the name of the text file without any extensions
%   like '.txt'. For example if there is an arena file under 'arenas'
%   folder with name 'myArena.txt', then the input must be just 'myArena'.
%   This function returns 'true' if it can find a 'txt' file with the
%   provided name under 'arenas' folder, else returns 'false'.

global params;

simRoot = getRootFolder();
path    = append(simRoot, "/arenas/", string(aname), ".txt");
file    = java.io.File(path);

if file.exists()
    params.arena.name = string(aname);
    tf = true;
else
    tf = false;
end






