function [trajHandle, params] = trajPresetLine(profile)
%TRAJPRESETLINE Sample parameters for the line trajectory generator.
%
%   Returns a handle to trajLine plus a struct with start and end positions
%   along with a desired completion time. The field ordering mirrors the
%   inputs to trajLine.
%
%   An optional profile argument selects from three presets: 'default'
%   matches the original diagonal move, 'short' keeps motion near the origin
%   for quick checks, and 'long' stretches the path across the arena with a
%   longer duration. The profile may be given as a name or as the numeric
%   index 1, 2, or 3 in the order listed above.

if nargin < 1 || isempty(profile)
    profile = 'default';
end

trajHandle = @trajLine;
profiles = {'default', 'short', 'long'};

if isnumeric(profile)
    if ~isscalar(profile) || profile < 1 || profile > numel(profiles) || profile ~= floor(profile)
        error('Profile index must be an integer from 1 to %d.', numel(profiles));
    end
    profile = profiles{profile};
elseif isstring(profile) || ischar(profile)
    profile = lower(profile);
else
    error('Profile must be a name or numeric index.');
end

switch profile
    case 'default'
        params.posStart = [0.0; 0.0];
        params.posEnd   = [0.5; 0.5];
        params.tEnd     = 10.0;
    case 'short'
        params.posStart = [0.0; 0.0];
        params.posEnd   = [0.25; 0.1];
        params.tEnd     = 6.0;
    case 'long'
        params.posStart = [-0.4; -0.4];
        params.posEnd   = [0.4; 0.4];
        params.tEnd     = 14.0;
    otherwise
        error('Unknown profile "%s". Use "default", "short", or "long" (or indices 1-3).', profile);
end
end
