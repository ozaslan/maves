function updatePlots()
%UPDATEPLOTS 
%   

global params;
global state;

if params.qcopter.visual.plotFreq == 0
    return;
end

hs  = params.plots.axesHandles;
kF = params.qcopter.phys.kF;

cxs    = state.qcopter.trajHist(2, :);
cys    = state.qcopter.trajHist(3, :);
cxdots = state.qcopter.trajHist(5, :);
cydots = state.qcopter.trajHist(6, :);
ts     = state.qcopter.traj(1, :);
xs     = state.qcopter.traj(2, :);
ys     = state.qcopter.traj(3, :);
ths    = state.qcopter.traj(4, :) / pi * 180;
xdots  = state.qcopter.traj(5, :);
ydots  = state.qcopter.traj(6, :);
thdots = state.qcopter.traj(7, :) / pi * 180;
f1s = state.qcopter.traj(8, :) .^2 * kF;
f2s = state.qcopter.traj(9, :) .^2 * kF;

cmdHist = state.qcopter.cmdHist;
if ~isempty(cmdHist)
    cmdTs     = cmdHist(1, :);
    thCmds    = cmdHist(2, :) / pi * 180;
    thDotCmds = cmdHist(3, :) / pi * 180;
    f1Cmds    = cmdHist(4, :);
    f2Cmds    = cmdHist(5, :);
else
    cmdTs     = [];
    thCmds    = [];
    thDotCmds = [];
    f1Cmds    = [];
    f2Cmds    = [];
end

plot(hs(1), ts,  xs , 'Color', 'r', 'LineStyle', '-',  'LineWidth', 2.0);
plot(hs(1), ts, cxs , 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2.0);
updateRmseText(hs(1), computeRmse(ts, xs, ts, cxs));
% legend(hs(1), 'act.', 'traj.');

plot(hs(2), ts,  xdots , 'Color', 'r', 'LineStyle', '-',  'LineWidth', 2.0);
plot(hs(2), ts, cxdots , 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2.0);
updateRmseText(hs(2), computeRmse(ts, xdots, ts, cxdots));
% legend(hs(2), 'act.', 'traj.');

plot(hs(3), ts, ys , 'Color', 'g', 'LineStyle', '-',  'LineWidth', 2.0);
plot(hs(3), ts, cys, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2.0);
updateRmseText(hs(3), computeRmse(ts, ys, ts, cys));
% legend(hs(3), 'act.', 'traj.');

plot(hs(4), ts,  ydots, 'Color', 'g', 'LineStyle', '-',  'LineWidth', 2.0);
plot(hs(4), ts, cydots, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2.0);
updateRmseText(hs(4), computeRmse(ts, ydots, ts, cydots));
% legend(hs(4), 'act.', 'traj.');

plot(hs(5), ts, ths , 'Color', 'b', 'LineStyle', '-',  'LineWidth', 2.0);
if ~isempty(thCmds)
    plot(hs(5), cmdTs, thCmds, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2.0);
end
updateRmseText(hs(5), computeRmse(ts, ths, cmdTs, thCmds));

plot(hs(6), ts, thdots, 'Color', 'b', 'LineStyle', '-',  'LineWidth', 2.0);
if ~isempty(thDotCmds)
    plot(hs(6), cmdTs, thDotCmds, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2.0);
end
updateRmseText(hs(6), computeRmse(ts, thdots, cmdTs, thDotCmds));

plot(hs(7), ts, f1s, 'Color', 'c', 'LineStyle', '-', 'LineWidth', 2.0);
if ~isempty(f1Cmds)
    plot(hs(7), cmdTs, f1Cmds, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2.0);
end
updateRmseText(hs(7), computeRmse(ts, f1s, cmdTs, f1Cmds));

plot(hs(8), ts, f2s, 'Color', 'c', 'LineStyle', '-', 'LineWidth', 2.0);
if ~isempty(f2Cmds)
    plot(hs(8), cmdTs, f2Cmds, 'Color', 'k', 'LineStyle', '--', 'LineWidth', 2.0);
end
updateRmseText(hs(8), computeRmse(ts, f2s, cmdTs, f2Cmds));

% drawnow();

updateStatusBar();

end

function updateRmseText(ax, rmse)
%UPDATERMSETEXT  Display RMSE text in the bottom-right corner of an axes.

if ~ishandle(ax) || ~isvalid(ax)
    return;
end

if isnan(rmse)
    label = 'RMSE: n/a';
else
    label = sprintf('RMSE: %.3f', rmse);
end

txt = findobj(ax, 'Type', 'text', 'Tag', 'rmseText', 'Parent', ax);

if isempty(txt) || ~isvalid(txt)
    text(ax, 0.98, 0.02, label, ...
        'Units', 'normalized', ...
        'HorizontalAlignment', 'right', ...
        'VerticalAlignment', 'bottom', ...
        'FontWeight', 'bold', ...
        'Color', [0.2, 0.2, 0.2], ...
        'Interpreter', 'none', ...
        'Tag', 'rmseText');
else
    set(txt, 'String', label);
end

end

function updateStatusBar()
%UPDATESTATUSBAR  Refresh the simulator status bar with live information.

global params;
global state;

if ~isfield(params.plots, 'statusTextHandles') || isempty(params.plots.statusTextHandles)
    return;
end

handles = params.plots.statusTextHandles;

if ~all(isfield(handles, {'time', 'pid', 'state'}))
    return;
end

handleCells = struct2cell(handles);
if ~all(cellfun(@(h) ishghandle(h) && isvalid(h), handleCells))
    return;
end

simTime = NaN;
if isfield(state, 'sim') && isfield(state.sim, 'stamp') && ~isempty(state.sim.stamp)
    simTime = state.sim.stamp;
end

if isnan(simTime)
    timeLabel = 'Sim Time: n/a';
else
    timeLabel = sprintf('Sim Time: %.2f s', simTime);
end
set(handles.time, 'String', timeLabel);

pidParams = [];
if isfield(params, 'controllerParams')
    pidParams = params.controllerParams;
end

if isempty(pidParams)
    if isfield(params, 'qcopter') && isfield(params.qcopter, 'phys')
        kp = getfield(params.qcopter.phys, 'kPth', NaN); %#ok<GFLD>
        kd = getfield(params.qcopter.phys, 'kDth', NaN); %#ok<GFLD>
        pidLabel = sprintf('PID: Kp=%.3g, Ki=n/a, Kd=%.3g', kp, kd);
    else
        pidLabel = 'PID: n/a';
    end
else
    pidParams = pidParams(:)';
    switch numel(pidParams)
        case 3
            pidLabel = sprintf('PID: Kp=%.3g, Ki=%.3g, Kd=%.3g', pidParams);
        case 4
            pidLabel = sprintf('PID: Kp=%.3g, Ki=%.3g, Kd=%.3g, Lim=%.3g', pidParams);
        otherwise
            pidLabel = sprintf('PID: %s', mat2str(pidParams, 3));
    end
end
set(handles.pid, 'String', pidLabel);

pose = [NaN; NaN; NaN];
vel  = [NaN; NaN; NaN];
if isfield(state, 'qcopter')
    if isfield(state.qcopter, 'pose') && numel(state.qcopter.pose) >= 3
        pose = state.qcopter.pose(1:3);
    end
    if isfield(state.qcopter, 'vel') && numel(state.qcopter.vel) >= 3
        vel = state.qcopter.vel(1:3);
    end
end
stateLabel = sprintf('Pos: [%.2f, %.2f, %.1f°]\nVel: [%.2f, %.2f, %.2f]', ...
    pose(1), pose(2), pose(3) * 180 / pi, vel(1), vel(2), vel(3));
set(handles.state, 'String', stateLabel);

end
