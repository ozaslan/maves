function setCaptureMode(mode)
%SETCAPTUREMODE Configure whether simulation visuals are saved.
%
%   setCaptureMode('save') - Save the arena figure to disk. In live
%                            visualization mode a video is recorded. In
%                            deferred mode only the final frame is saved as
%                            an image once the physics completes.
%   setCaptureMode('none') - Disable saving (default).

global params;

if nargin < 1 || isempty(mode)
    mode = 'none';
end

if isstring(mode)
    if ~isscalar(mode)
        error('Capture mode must be a single string or character vector.');
    end
    mode = char(mode);
end

validModes = {'save', 'none'};
mode = validatestring(mode, validModes, mfilename, 'mode');

if ~isfield(params, 'sim') || isempty(params.sim)
    params.sim = struct();
end

if ~isfield(params.sim, 'capture') || isempty(params.sim.capture)
    params.sim.capture = struct();
end

% Close any existing writer before reconfiguring capture mode.
if isfield(params.sim.capture, 'isRecording') && params.sim.capture.isRecording
    writer = params.sim.capture.writer;
    try
        close(writer);
    catch
    end
end

params.sim.capture.mode = mode;
params.sim.capture.writer = [];
params.sim.capture.isRecording = false;
params.sim.capture.imageSaved = false;

if strcmp(mode, 'save')
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    params.sim.capture.timestamp = timestamp;

    runsimPath = which('runsim');
    if isempty(runsimPath)
        % Fallback to the directory containing this helper if runsim cannot be
        % located on the MATLAB path.
        helperPath = mfilename('fullpath');
        if isempty(helperPath)
            runsimPath = pwd;
        else
            runsimPath = fileparts(fileparts(helperPath));
        end
    else
        runsimPath = fileparts(runsimPath);
    end

    screenshotsDir = fullfile(runsimPath, 'screenshots');
    if exist(screenshotsDir, 'dir') ~= 7
        [status, msg, msgId] = mkdir(screenshotsDir);
        if ~status
            error('setCaptureMode:mkdirFailed', ...
                'Unable to create screenshots directory "%s": %s (%s).', ...
                screenshotsDir, msg, msgId);
        end
    end

    params.sim.capture.outputDir = screenshotsDir;
    params.sim.capture.videoFile = fullfile(screenshotsDir, ...
        sprintf('maves_video_%s.mp4', timestamp));
    params.sim.capture.imageFile = fullfile(screenshotsDir, ...
        sprintf('maves_image_%s.png', timestamp));
else
    params.sim.capture.timestamp = '';
    params.sim.capture.videoFile = '';
    params.sim.capture.imageFile = '';
    params.sim.capture.outputDir = '';
end

