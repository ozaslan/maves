function [trajHandle, params] = trajPresetDiamond(profile)
%TRAJPRESETDIAMOND Sample parameters for the diamond trajectory generator.
%
%   Returns a handle to trajDiamond plus a struct with four corner points and
%   a desired completion time. The fields align with the arguments expected by
%   trajDiamond.
%
%   An optional profile argument selects from three presets: 'default'
%   matches the original points, 'compact' shrinks the diamond for quicker
%   runs, and 'stretched' elongates the shape while staying within the arena
%   bounds. The profile may be given as a name or as the numeric index 1, 2,
%   or 3 in the order listed above.

if nargin < 1 || isempty(profile)
    profile = 'default';
end

trajHandle = @trajDiamond;
profiles = {'default', 'compact', 'stretched'};

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
        params.p0  = [0.0; 0.0];
        params.p1  = [0.5; 0.5];
        params.p2  = [0.0; 1.0];
        params.p3  = [-0.5; 0.5];
        params.tEnd = 10.0;
    case 'compact'
        params.p0  = [0.0; 0.0];
        params.p1  = [0.35; 0.35];
        params.p2  = [0.0; 0.6];
        params.p3  = [-0.35; 0.35];
        params.tEnd = 8.0;
    case 'stretched'
        params.p0  = [0.0; -0.1];
        params.p1  = [0.45; 0.45];
        params.p2  = [0.0; 0.9];
        params.p3  = [-0.45; 0.45];
        params.tEnd = 12.0;
    otherwise
        error('Unknown profile "%s". Use "default", "compact", or "stretched" (or indices 1-3).', profile);
end
end
