function obs = getObstacles()
%GETOBSTACLES parses a text file which includes a list of obstacles
%
%   This function parses a text file located under 'arenas' folder and
%   returns a cell array of obstacles.

path  = getArenaPath();
lines = readlines(path, ...
                    "WhitespaceRule", "trim", ...
                    "EmptyLineRule", "skip");            

obs = {};
                
for i = 1 : length(lines)
    line = lines(i);
    parts = split(line);
    
    type = char(parts(1));
    
    if type(1) == '#'
        continue;
    end
    
    vals = str2double(parts(2:end));
    
    switch type
        case "circle"
            assert(length(vals) == 3, "Circle requires exactly 3 parameters");
            newObs.type = 'c';
            newObs.center = vals(1:2);
            newObs.radius = vals(3);
        case "box"
            assert(length(vals) == 4, "Box requires exactly 4 parameters");
            newObs.type = 'b';
            newObs.center = vals(1:2);
            newObs.width  = vals(3);
            newObs.height = vals(4);
        otherwise
            error("Unknown obstacle type");
    end
    
    obs{end + 1, 1} = newObs;
end


