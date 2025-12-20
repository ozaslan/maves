function [trajHandle, params] = trajPresetCircle(profile)
%TRAJPRESETCIRCLE Sample parameters for the circle trajectory generator.
%
%   Returns a handle to trajCircle plus a struct that bundles the circle
%   center, radius, starting angle along the curve, and desired completion
%   time. The center, radius, and timing reflect the sample setup in
%   runsim.m.
%
%   An optional profile argument selects from three presets: 'default'
%   matches the original circular path, 'tight' shrinks the radius for a
%   compact loop, and 'wide' shifts the center slightly while keeping the
%   trajectory within the arena limits. The profile may be given as a name
%   or as the numeric index 1, 2, or 3 in the order listed above.

if nargin < 1 || isempty(profile)
    profile = 'default';
end

trajHandle = @trajCircle;
profiles = {'default', 'tight', 'wide'};

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
        params.center      = [0.0; 0.0];
        params.radius      = 0.5;
        params.startAngle  = 0.0;  % radians
        params.tEnd        = 10.0;
    case 'tight'
        params.center      = [0.1; -0.1];
        params.radius      = 0.25;
        params.startAngle  = pi/4;
        params.tEnd        = 8.0;
    case 'wide'
        params.center      = [-0.1; 0.1];
        params.radius      = 0.4;
        params.startAngle  = 0.0;
        params.tEnd        = 12.0;
    otherwise
        error('Unknown profile "%s". Use "default", "tight", or "wide" (or indices 1-3).', profile);
end
end
