function params = controllerPresets(controllerType, profile)
%CONTROLLERPRESETS Return preset controller parameters.
%
%   params = controllerPresets('pid') returns the default PID gain vector
%   formatted for use with setController(): proportional, integral,
%   derivative, and an integral limit.
%
%   params = controllerPresets('lqr') returns the default LQR parameter
%   struct with the safety and tuning limits used by the provided LQR
%   controller implementation.
%
%   An optional profile can be supplied to get more aggressive presets:
%   controllerPresets(controllerType, 'aggressive').
%
%   These presets are provided for convenience when exploring different
%   controllers; they are not wired into the simulator by default.

arguments
    controllerType (1, :) char
    profile (1, :) char = 'default'
end

controllerType = lower(controllerType);
profile = lower(profile);

switch controllerType
    case 'pid'
        params = pidParams(profile);
    case 'lqr'
        params = lqrParams(profile);
    otherwise
        error('Unknown controller preset "%s". Use either "pid" or "lqr".', controllerType);
end

end

function pidValues = pidParams(profile)
%PIDPARAMS PID gains used throughout the sample simulation setup.
%
%   The ordering matches the expected [kp; ki; kd; integralLimit] vector
%   used when registering the controller via setController().

switch profile
    case 'default'
        pidValues = [4.5; 1.5; 3.5; 5.0];
    case 'aggressive'
        pidValues = [6.0; 2.5; 5.0; 5.0];
    otherwise
        error('Unknown PID profile "%s". Use "default" or "aggressive".', profile);
end

end

function lqrValues = lqrParams(profile)
%LQRPARAMS LQR tuning parameters matching the reference implementation.

base = struct();
base.x_max      = 0.5;          % meters
base.y_max      = 0.5;          % meters
base.xd_max     = 1.0;          % m/s
base.yd_max     = 1.0;          % m/s
base.th_max     = deg2rad(10);  % radians
base.Fdev_max   = 0.3;          % fraction of mg (=> +/-0.3*mg)
base.R_F_scale  = 1.0;
base.R_th_scale = 1.0;

switch profile
    case 'default'
        lqrValues = base;
    case 'aggressive'
        lqrValues = base;
        lqrValues.xd_max     = 1.5;          % allow faster lateral velocity
        lqrValues.yd_max     = 1.5;
        lqrValues.th_max     = deg2rad(15);  % permit steeper attitude
        lqrValues.Fdev_max   = 0.45;         % allow more thrust deviation
        lqrValues.R_F_scale  = 0.7;          % lower penalty for force use
        lqrValues.R_th_scale = 0.7;          % lower penalty for attitude effort
    otherwise
        error('Unknown LQR profile "%s". Use "default" or "aggressive".', profile);
end

end
