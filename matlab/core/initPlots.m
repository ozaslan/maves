function initPlots()
%INITPLOTS
%

global params;

if params.qcopter.visual.plotFreq == 0
    if ~isempty(params.plots.panelHandle) && isvalid(params.plots.panelHandle)
        delete(findall(params.plots.panelHandle, 'type', 'axes'));
    end
    params.plots.axesHandles = [];
    return;
end

if isempty(params.plots.layoutHandle) || ~isvalid(params.plots.layoutHandle)
    error('Plot layout has not been initialized. Call initArena() first.');
end

delete(findall(params.plots.panelHandle, 'type', 'axes'));

labels = {'x (m)', '$\dot{x}$ (m/s)', ...
          'y (m)', '$\dot{y}$ (m/s)', ...
          '$\theta$ (deg)', '$\dot{\theta}$ (deg/s)', ...
          '$F_1$ (N)', '$F_2$ (N)'};

params.plots.axesHandles = gobjects(1, 8);

for i = 1 : 8
    % Use nexttile to create axes that are correctly managed by the tiledlayout.
    % Creating axes manually and assigning the Layout.Tile property would fail
    % when the axes handle is empty, which is the case during the first
    % iteration of the loop. By using nexttile the axes is created with the
    % proper parent/layout relationship and the layout manager handles the
    % placement automatically.
    h = nexttile(params.plots.layoutHandle, i);
    cla(h);
    hold(h, 'on');
    grid(h, 'on');
    axis(h, 'tight');
    set(h, 'TitleFontWeight', 'light');
    set(h, 'FontAngle', 'italic');
    yLabelHandle = ylabel(h, labels{i}, 'interpreter','latex');
    set(yLabelHandle, 'FontWeight', 'bold');

    isRightPanel = any(i == [2, 4, 6, 8]);
    if isRightPanel
        set(h, 'YAxisLocation', 'right');
        set(yLabelHandle, 'FontWeight', 'bold');
    end

    if any(i == [3, 4, 5, 6])
        % set(h, 'xtick',[]);
        set(h, 'xticklabel',[]);
    end

    if any(i == [7, 8])
        xLabelHandle = xlabel(h, 'Times (sec.)');
        set(xLabelHandle, 'FontWeight', 'bold');
    elseif any(i == [1, 2])
        xLabelHandle = xlabel(h, 'Times (sec.)');
        set(h, 'XAxisLocation', 'top');
        set(xLabelHandle, 'FontWeight', 'bold');
    end

    params.plots.axesHandles(i) = h;
end

drawnow();



