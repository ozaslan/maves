function drawQuadcopter()
%DRAWQUADCOPTER This draws a simple visual of a quadcopter on a plane. 
%
global params;

h = params.arena.axesHandle;

pose = getPose();
x  = pose(1);
y  = pose(2);
th = pose(3);

T = [cos(th) -sin(th) x;
     sin(th)  cos(th) y;
          0        0  1];

%% DRAW BOOM
pts       = [];
pts(:, 1) = [params.qcopter.visual.boomLength; 0];
pts(:, 2) = -pts(:, 1);
pts(3, :) = 1;
pts = T * pts;

plot(params.arena.axesHandle, pts(1, :), pts(2, :), ...
     params.qcopter.visual.bodyColor, ...
     'LineWidth', 3);
 
%% DRAW BODY
pts       = [];
pts(:, 1) = [params.qcopter.visual.bodyLength; ...
             params.qcopter.visual.bodyHeight] / 2;
pts(:, 2) = [-1;  1] .* pts(:, 1);
pts(:, 3) = [-1; -1] .* pts(:, 1);
pts(:, 4) = [ 1; -1] .* pts(:, 1);
pts(3, :) = 1;
pts = T * pts;

patch(params.arena.axesHandle, ...
        pts(1, :), pts(2, :), ...
        params.qcopter.visual.bodyColor);
%% DRAW PROPELLERS
pts       = [];
pts(:, 1) = [ 1/2, 1/5] * params.qcopter.visual.propSize;
pts(:, 2) = [-1/2, 1/5] * params.qcopter.visual.propSize;
pts(1, :) = pts(1, :) + params.qcopter.visual.boomLength;
pts(3, :) = 1;
pts = T * pts;

plot(params.arena.axesHandle, pts(1, :), pts(2, :), ...
     params.qcopter.visual.propColor, ...
     'LineWidth', 2);
 
pts       = [];
pts(:, 1) = [ 1/2, 1/5] * params.qcopter.visual.propSize;
pts(:, 2) = [-1/2, 1/5] * params.qcopter.visual.propSize;
pts(1, :) = pts(1, :) - params.qcopter.visual.boomLength;
pts(3, :) = 1;
pts = T * pts;
 
plot(params.arena.axesHandle, pts(1, :), pts(2, :), ...
     params.qcopter.visual.propColor, ...
     'LineWidth', 2);
 
%% DRAW FORCES
fs = getForces();

dfs = fs - mean(fs);
fs  = mean(fs) + 25 * dfs;
fs  = fs / 5;

pts       = [];
pts(:, 1) = [ -params.qcopter.visual.boomLength, ...
              params.qcopter.visual.propSize / 5 ];
pts(:, 2) = [ +params.qcopter.visual.boomLength, ...
              params.qcopter.visual.propSize / 5 ];
pts(3, :) = 1;
pts = T * pts;

fs = T(1:2, 1:2) * [[0; fs(2)], [0; fs(1)]];

quiver(h, pts(1, :), pts(2, :), fs(1, :) , fs(2, :), 'off'); 

% drawnow();