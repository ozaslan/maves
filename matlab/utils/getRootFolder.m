function path = getRootFolder()
%GETROOTFOLDER returns path to simulator root folder
%   This function returns the path to where the 'runsim.m' script sits.

file = java.io.File(mfilename('fullpath'));
path = string(file.getParentFile().getParentFile().getCanonicalPath());