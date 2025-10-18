function initArena()
%%SETUPARENA   Initialize the figure and axes to draw arena
%
%   This function initializes the figure and the axes where the arena,
%   quadcopter and obstacles are drawn. 
global params;

if params.closeAllFigures
    close all;
end

params.arena.figHandle  = figure(params.arena.figIndex);
clf(params.arena.figHandle);

params.arena.resizeComplete = false;

figHandle = params.arena.figHandle;

% Configure the arena figure to occupy half of the available monitor
% resolution and center it on the screen before any visual capture is
% performed.
originalRootUnits = get(0, 'Units');
set(0, 'Units', 'pixels');
screenSize = get(0, 'ScreenSize');
set(0, 'Units', originalRootUnits);

targetWidth = max(1, round(screenSize(3) / 2));
targetHeight = max(1, round(screenSize(4) / 2));
targetLeft = screenSize(1) + round((screenSize(3) - targetWidth) / 2);
targetBottom = screenSize(2) + round((screenSize(4) - targetHeight) / 2);

originalFigUnits = get(figHandle, 'Units');
set(figHandle, 'Units', 'pixels');
set(figHandle, 'Position', [targetLeft, targetBottom, targetWidth, targetHeight]);
set(figHandle, 'Units', originalFigUnits);

arenaAxes = axes('Parent', params.arena.figHandle, ...
                 'Units', 'normalized', ...
                 'Position', [0.03, 0.06, 0.49, 0.9]);
cla(arenaAxes);
hold(arenaAxes, 'on');
grid(arenaAxes, 'on');

set(arenaAxes, 'TitleFontWeight', 'light');
set(arenaAxes, 'FontAngle', 'italic');
title(arenaAxes, params.arena.title);

axis(arenaAxes, 'equal');
axis(arenaAxes, 'auto xy');
axis(arenaAxes, 'padded');

params.arena.axesHandle = arenaAxes;
params.arena.dynamicLimits = [];

set(arenaAxes, 'XLim', [0, 1e-3], ...
                'YLim', [0, 1e-3], ...
                'XLimMode', 'manual', ...
                'YLimMode', 'manual');

params.plots.figHandle = params.arena.figHandle;
params.plots.panelHandle = uipanel('Parent', params.arena.figHandle, ...
                                   'Units', 'normalized', ...
                                   'Position', [0.52, 0.06, 0.45, 0.9], ...
                                   'BorderType', 'none');
params.plots.layoutHandle = tiledlayout(params.plots.panelHandle, 4, 2, ...
                                        'TileSpacing', 'compact', ...
                                        'Padding', 'compact');
params.plots.axesHandles = [];

statusBg = [0.94, 0.95, 0.99];
statusPanel = uipanel('Parent', params.arena.figHandle, ...
                      'Units', 'normalized', ...
                      'Position', [0.52, 0.01, 0.45, 0.06], ...
                      'BackgroundColor', statusBg, ...
                      'BorderType', 'line', ...
                      'BorderWidth', 1, ...
                      'ForegroundColor', [0.7, 0.7, 0.7]);

timeText = uicontrol('Parent', statusPanel, ...
                     'Style', 'text', ...
                     'Units', 'normalized', ...
                     'Position', [0.02, 0.1, 0.28, 0.8], ...
                     'String', 'Time: --:--:--', ...
                     'HorizontalAlignment', 'left', ...
                     'FontWeight', 'bold', ...
                     'BackgroundColor', statusBg);

pidText = uicontrol('Parent', statusPanel, ...
                    'Style', 'text', ...
                    'Units', 'normalized', ...
                    'Position', [0.32, 0.1, 0.32, 0.8], ...
                    'String', 'PID: n/a', ...
                    'HorizontalAlignment', 'left', ...
                    'BackgroundColor', statusBg);

stateText = uicontrol('Parent', statusPanel, ...
                      'Style', 'text', ...
                      'Units', 'normalized', ...
                      'Position', [0.65, 0.1, 0.33, 0.8], ...
                      'String', sprintf('Pos: [--, --, --]\nVel: [--, --, --]'), ...
                      'HorizontalAlignment', 'left', ...
                      'BackgroundColor', statusBg);

params.plots.statusPanelHandle = statusPanel;
params.plots.statusTextHandles = struct('time', timeText, ...
                                        'pid', pidText, ...
                                        'state', stateText);

% Display the figure size in the bottom-left corner and update it whenever
% the window is resized.
sizeLabelBg = get(figHandle, 'Color');
sizeText = uicontrol('Parent', figHandle, ...
                     'Style', 'text', ...
                     'Units', 'pixels', ...
                     'Position', [0, 0, 1, 1], ...
                     'HorizontalAlignment', 'left', ...
                     'FontSize', 10, ...
                     'FontWeight', 'normal', ...
                     'BackgroundColor', sizeLabelBg, ...
                     'String', '');
uistack(sizeText, 'top');
params.arena.sizeTextHandle = sizeText;

set(figHandle, 'SizeChangedFcn', @onArenaFigureSizeChanged);

updateArenaFigureSizeDisplay();
drawnow();

params.arena.resizeComplete = true;


end

function onArenaFigureSizeChanged(~, ~)
    global params;

    if ~isfield(params, 'arena')
        return;
    end

    params.arena.resizeComplete = false;
    updateArenaFigureSizeDisplay();
    params.arena.resizeComplete = true;

end

function updateArenaFigureSizeDisplay()
    global params;

    if ~isfield(params, 'arena')
        return;
    end

    figHandle = params.arena.figHandle;
    if isempty(figHandle) || ~ishandle(figHandle)
        return;
    end

    sizeText = [];
    if isfield(params.arena, 'sizeTextHandle')
        sizeText = params.arena.sizeTextHandle;
    end

    if isempty(sizeText) || ~ishandle(sizeText)
        return;
    end

    originalUnits = get(figHandle, 'Units');
    set(figHandle, 'Units', 'pixels');
    figPos = get(figHandle, 'Position');
    set(figHandle, 'Units', originalUnits);

    widthPx = max(0, round(figPos(3)));
    heightPx = max(0, round(figPos(4)));

    margin = 12;
    labelWidth = 180;
    labelHeight = 22;

    left = margin;
    bottom = margin;

    set(sizeText, 'Units', 'pixels', ...
        'Position', [left, bottom, labelWidth, labelHeight], ...
        'String', sprintf('Size: %d x %d px', widthPx, heightPx));

end


