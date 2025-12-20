function [trajHandle, params] = trajPresetHover(profile)
%TRAJPRESETHOVER Sample hover point used to anchor a hover trajectory.
%
%   Returns a handle to trajHover along with a 2-by-1 position vector that
%   can be passed to setTrajectoryGenerator to command the quadrotor to hold
%   position at that point.
%
%   An optional profile argument selects from three presets: 'default' holds
%   station at the origin, 'offset' hovers at a forward-right location, and
%   'corner' moves to the top-right of the arena bounds. The profile may be
%   given as a name or as the numeric index 1, 2, or 3 in the order listed
%   above.

if nargin < 1 || isempty(profile)
    profile = 'default';
end

trajHandle = @trajHover;
profiles = {'default', 'offset', 'corner'};

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
        params = [0.0; 0.0];
    case 'offset'
        params = [0.25; 0.2];
    case 'corner'
        params = [0.5; 0.5];
    otherwise
        error('Unknown profile "%s". Use "default", "offset", or "corner" (or indices 1-3).', profile);
end
end
