function handleCaptureUpdate(forceDraw)
%HANDLECAPTUREUPDATE Persist arena visuals to disk when requested.
%
%   handleCaptureUpdate(FORCEDRAW) records a frame of the arena figure or
%   exports a PNG snapshot depending on the simulator configuration. The
%   helper inspects the global simulator parameters to determine whether the
%   user requested saving visuals via SETCAPTUREMODE and whether the
%   simulation is running in live or deferred mode.
%
%   The FORCEDRAW flag should be true when the simulation is stopping or the
%   deferred run completed so that the helper can flush pending video
%   writers and take the final screenshot.

persistent frameBuffer frameBufferCount bufferTimestamp bufferChunkSize;

if isempty(frameBuffer)
    frameBuffer = {};
end
if isempty(frameBufferCount)
    frameBufferCount = 0;
end
if isempty(bufferTimestamp)
    bufferTimestamp = '';
end
if isempty(bufferChunkSize)
    bufferChunkSize = 0;
end

if nargin < 1
    forceDraw = false;
end

global params;

if ~isfield(params, 'sim') || ~isfield(params.sim, 'capture')
    resetFrameBuffer();
    return;
end

captureCfg = params.sim.capture;
if ~isfield(captureCfg, 'mode') || ~strcmp(captureCfg.mode, 'save')
    resetFrameBuffer();
    return;
end

if ~isfield(params, 'arena') || ~isfield(params.arena, 'figHandle')
    resetFrameBuffer();
    return;
end

figHandle = params.arena.figHandle;
if isempty(figHandle) || ~ishandle(figHandle)
    resetFrameBuffer();
    return;
end

if isfield(params.arena, 'resizeComplete') && ~params.arena.resizeComplete
    resetFrameBuffer();
    return;
end

% Ensure timestamps and filenames are available even if the capture mode was
% configured after initialization.
if ~isfield(captureCfg, 'timestamp') || isempty(captureCfg.timestamp)
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    params.sim.capture.timestamp = timestamp;

    outputDir = '';
    if isfield(captureCfg, 'outputDir')
        outputDir = captureCfg.outputDir;
    end

    if isempty(outputDir)
        runsimPath = which('runsim');
        if isempty(runsimPath)
            helperPath = mfilename('fullpath');
            if isempty(helperPath)
                runsimPath = pwd;
            else
                runsimPath = fileparts(fileparts(helperPath));
            end
        else
            runsimPath = fileparts(runsimPath);
        end
        outputDir = fullfile(runsimPath, 'screenshots');
    end

    if exist(outputDir, 'dir') ~= 7
        [status, msg, msgId] = mkdir(outputDir);
        if ~status
            error('handleCaptureUpdate:mkdirFailed', ...
                'Unable to create screenshots directory "%s": %s (%s).', ...
                outputDir, msg, msgId);
        end
    end

    params.sim.capture.outputDir = outputDir;
    params.sim.capture.videoFile = fullfile(outputDir, ...
        sprintf('maves_video_%s.mp4', timestamp));
    params.sim.capture.imageFile = fullfile(outputDir, ...
        sprintf('maves_image_%s.png', timestamp));
    captureCfg = params.sim.capture;
end

runMode = '';
if isfield(params.sim, 'runMode') && ~isempty(params.sim.runMode)
    runMode = params.sim.runMode;
end

if strcmpi(runMode, 'live')
    % Track how many frames have been written and the corresponding
    % simulation time so that we can derive an accurate playback speed for
    % the recorded video.  These fields are initialised lazily to avoid
    % polluting the capture configuration when saving is disabled.
    if ~isfield(captureCfg, 'frameCount') || isempty(captureCfg.frameCount)
        captureCfg.frameCount = 0;
    end
    if ~isfield(captureCfg, 'totalSimDuration') || ...
            isempty(captureCfg.totalSimDuration)
        captureCfg.totalSimDuration = 0;
    end
    if ~isfield(captureCfg, 'lastSimStamp') || isempty(captureCfg.lastSimStamp)
        captureCfg.lastSimStamp = [];
    end
    if ~isfield(captureCfg, 'derivedFrameRate') || ...
            isempty(captureCfg.derivedFrameRate)
        captureCfg.derivedFrameRate = [];
    end
    if ~strcmp(bufferTimestamp, captureCfg.timestamp)
        frameBuffer = {};
        frameBufferCount = 0;
        bufferTimestamp = captureCfg.timestamp;
        bufferChunkSize = 0;
    end

    [simStamp, ~] = getStamp();

    if ~isempty(captureCfg.lastSimStamp)
        deltaT = simStamp - captureCfg.lastSimStamp;
        if isfinite(deltaT)
            captureCfg.totalSimDuration = captureCfg.totalSimDuration + ...
                max(deltaT, 0);
        end
    end

    captureCfg.frameCount = captureCfg.frameCount + 1;
    captureCfg.lastSimStamp = simStamp;

    frame = getframe(figHandle);

    if ~isfield(captureCfg, 'isRecording') || ~captureCfg.isRecording
        if bufferChunkSize <= 0
            % Reserve enough room for approximately one second of video to
            % minimise buffer resizing when live capture runs for extended
            % periods before the writer is opened.
            bufferChunkSize = max(8, ceil(params.sim.freq));
        end
        if frameBufferCount >= numel(frameBuffer)
            frameBuffer = [frameBuffer, cell(1, bufferChunkSize)]; %#ok<AGROW>
        end

        frameBufferCount = frameBufferCount + 1;
        frameBuffer{frameBufferCount} = frame;

        shouldStartRecording = captureCfg.frameCount >= 2 || forceDraw;

        if shouldStartRecording
            videoPath = params.sim.capture.videoFile;
            profile = 'MPEG-4';
            try
                writer = VideoWriter(videoPath, profile);
            catch err
                if contains(lower(err.message), 'profile is not valid')
                    warning(['Falling back to Motion JPEG AVI video capture ', ...
                        'because the "%s" profile is unavailable.'], profile);
                    [videoDir, videoName, ~] = fileparts(videoPath);
                    altVideoPath = fullfile(videoDir, [videoName, '.avi']);
                    params.sim.capture.videoFile = altVideoPath;
                    writer = VideoWriter(altVideoPath, 'Motion JPEG AVI');
                else
                    rethrow(err);
                end
            end

            derivedRate = params.sim.freq;
            if captureCfg.frameCount > 1 && captureCfg.totalSimDuration > 0
                derivedRate = (captureCfg.frameCount - 1) / ...
                    captureCfg.totalSimDuration;
            end
            if ~isfinite(derivedRate) || derivedRate <= 0
                derivedRate = params.sim.freq;
            end

            captureCfg.derivedFrameRate = derivedRate;
            writer.FrameRate = derivedRate / 2;
            open(writer);

            for idx = 1:frameBufferCount
                writeVideo(writer, frameBuffer{idx});
            end

            frameBuffer = {};
            frameBufferCount = 0;
            bufferChunkSize = 0;
            captureCfg.isRecording = true;
            params.sim.capture.writer = writer;
            params.sim.capture.isRecording = true;
        else
            params.sim.capture.frameCount = captureCfg.frameCount;
            params.sim.capture.totalSimDuration = captureCfg.totalSimDuration;
            params.sim.capture.lastSimStamp = captureCfg.lastSimStamp;
            params.sim.capture.derivedFrameRate = captureCfg.derivedFrameRate;
            params.sim.capture.isRecording = false;
            params.sim.capture.writer = [];
            return;
        end
    else
        writeVideo(params.sim.capture.writer, frame);
        if captureCfg.frameCount > 1 && captureCfg.totalSimDuration > 0
            captureCfg.derivedFrameRate = (captureCfg.frameCount - 1) / ...
                captureCfg.totalSimDuration;
        end
    end

    if forceDraw
        writer = params.sim.capture.writer;
        if ~isempty(writer)
            videoPath = params.sim.capture.videoFile;
            close(writer);
            fprintf('Saved arena recording to: %s\n', videoPath);
        end
        params.sim.capture.writer = [];
        params.sim.capture.isRecording = false;
        captureCfg.isRecording = false;
        frameBuffer = {};
        frameBufferCount = 0;
        bufferTimestamp = '';
        bufferChunkSize = 0;
    end

    params.sim.capture.frameCount = captureCfg.frameCount;
    params.sim.capture.totalSimDuration = captureCfg.totalSimDuration;
    params.sim.capture.lastSimStamp = captureCfg.lastSimStamp;
    params.sim.capture.derivedFrameRate = captureCfg.derivedFrameRate;
else
    if forceDraw && (~isfield(captureCfg, 'imageSaved') || ~captureCfg.imageSaved)
        frame = getframe(figHandle);
        imwrite(frame.cdata, params.sim.capture.imageFile);
        params.sim.capture.imageSaved = true;
        fprintf('Saved arena snapshot to: %s\n', params.sim.capture.imageFile);
    end
    resetFrameBuffer();
end

end

function resetFrameBuffer()
        frameBuffer = {};
        frameBufferCount = 0;
        bufferTimestamp = '';
        bufferChunkSize = 0;

        global params;
        if isstruct(params) && isfield(params, 'sim') && ...
                isfield(params.sim, 'capture') && ...
                isfield(params.sim.capture, 'bufferedFrames')
            params.sim.capture.bufferedFrames = {};
        end
    end
