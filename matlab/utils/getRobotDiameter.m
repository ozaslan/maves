function d = getRobotDiameter()
%GETROBOTDIAMETER returns the approximate diameter of the quadcopter
%   

global params;

d = max(params.qcopter.visual.bodyLength, ...
        params.qcopter.visual.bodyHeight) + 0.05;

