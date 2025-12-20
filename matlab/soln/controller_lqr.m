function u = controller_lqr(t, s, lqrParams)
%CONTROLLER_LQR  Outer-loop LQR position controller.
%
%   This controller replaces the PID outer-loop in controller.m with a
%   continuous-time LQR designed around the hover linearization under the
%   small-angle approximation:
%       xddot  ≈ -g * theta
%       yddot  ≈ -g + (1/m) * F
%
%   The controller outputs:
%       u = [F; theta_des]
%
%   Inputs
%   ------
%   t : current time stamp (scalar)
%   s : state vector (8x1), same convention as getStateVector()
%   lqrParams : structure or numeric vector specifying LQR weights.
%
%   Recommended: pass a STRUCT when registering via setController():
%       p = struct();
%       p.x_max     = 0.5;          % [m]
%       p.y_max     = 0.5;          % [m]
%       p.th_max    = deg2rad(10);  % [rad]
%       p.xd_max    = 1.0;          % [m/s]
%       p.yd_max    = 1.0;          % [m/s]
%       p.Fdev_max  = 0.3;          % as fraction of mg (e.g. 0.3 => +/-0.3*mg)
%       p.thd_max   = deg2rad(60);  % [rad/s] (optional, only if state includes thdot)
%       p.R_F_scale = 1.0;          % optional scalar multiplier for R(1,1)
%       p.R_th_scale= 1.0;          % optional scalar multiplier for R(2,2)
%
%   If a numeric vector is provided, interpret it as:
%       [qx qy qxd qyd rF rth]
%   which sets Q = diag([qx qy qxd qyd]) and R = diag([rF rth]).
%
%   Notes
%   -----
%   - This is an OUTER-LOOP design. Attitude tracking is handled elsewhere.
%   - We track the trajectory by regulating the error state:
%         e = [x - xT; y - yT; xdot - xdotT; ydot - ydotT]
%     and adding feedforward terms from the trajectory accel:
%         xddot_ff = xddotT,  yddot_ff = yddotT.
%
%   Requires Control System Toolbox for lqr().

assert(isscalar(t));
assert(all(size(s) == [8, 1]));

if nargin < 3
    error(['LQR parameters must be supplied when registering the ', ...
        'controller using setController().']);
end

u = zeros(2, 1);

g = getG();
[m, ~] = getInertia();

% Trajectory state (convention used by your PID controller):
% sT(1:2): pos [x;y]
% sT(4:5): vel [xdot;ydot]
% sT(7:8): acc [xddot;yddot]
sT = evalTrajectory(t, s);

% Build error state for outer-loop linear model:
% e = [x;y;xdot;ydot] - [xT;yT;xdotT;ydotT]
e = [ s(1) - sT(1);
      s(2) - sT(2);
      s(4) - sT(4);
      s(5) - sT(5) ];

% Hover-linearized outer-loop dynamics (small-angle):
%   xdot   = xdot
%   ydot   = ydot
%   xddot  = -g * theta
%   yddot  = (1/m) * F_dev     where F_dev = F - mg
%
% State:  [x; y; xdot; ydot]
% Input:  [F_dev; theta]
A = [ 0 0 1 0;
      0 0 0 1;
      0 0 0 0;
      0 0 0 0 ];

B = [ 0      0;
      0      0;
      0     -g;
      1/m    0 ];

% Compute and cache K
persistent K_cached params_cached
if isempty(K_cached) || ~isequaln(params_cached, lqrParams)
    [Q, R] = local_make_QR(lqrParams, m, g);
    % Continuous-time LQR gain: u = -K x
    K_cached = lqr(A, B, Q, R);
    params_cached = lqrParams;
end
K = K_cached;

% Feedback in deviation variables:
u_dev = -K * e;     % [F_dev; theta_cmd] correction

% Add feedforward from desired accelerations:
xddot_ff = sT(7);
ydotdot_ff = sT(8);

% Convert desired accelerations to feedforward commands:
theta_ff = -xddot_ff / g;          % from xddot ≈ -g*theta
Fdev_ff  =  m * ydotdot_ff;        % from yddot ≈ (1/m)*F_dev

theta_cmd = theta_ff + u_dev(2);
F_dev_cmd = Fdev_ff  + u_dev(1);

% Convert back to absolute thrust:
F_cmd = m*g + F_dev_cmd;

u = [F_cmd; theta_cmd];

end

% ----------------- helpers -----------------
function [Q, R] = local_make_QR(p, m, g)
%LOCAL_MAKE_QR  Build LQR weights.
% If p is struct: use Bryson-style normalization.
% If p is numeric vector [qx qy qxd qyd rF rth]: use directly.

if isstruct(p)
    % Defaults if not provided
    x_max    = local_getfield(p, 'x_max',     0.5);
    y_max    = local_getfield(p, 'y_max',     0.5);
    xd_max   = local_getfield(p, 'xd_max',    1.0);
    yd_max   = local_getfield(p, 'yd_max',    1.0);

    % Input bounds are for F_dev and theta
    th_max   = local_getfield(p, 'th_max',    deg2rad(10));

    % Fdev_max can be specified as fraction of mg (common) or absolute N.
    Fdev_max = local_getfield(p, 'Fdev_max',  0.3); % default: 0.3*mg as fraction
    if Fdev_max <= 2  % interpret <=2 as "fraction of mg" (heuristic, documented)
        Fdev_max = abs(Fdev_max) * (m*g);
    else
        Fdev_max = abs(Fdev_max); % absolute Newtons
    end

    R_F_scale  = local_getfield(p, 'R_F_scale',  1.0);
    R_th_scale = local_getfield(p, 'R_th_scale', 1.0);

    Q = diag([ 1/(x_max^2), 1/(y_max^2), 1/(xd_max^2), 1/(yd_max^2) ]);
    R = diag([ (R_F_scale) * 1/(Fdev_max^2), (R_th_scale) * 1/(th_max^2) ]);

elseif isnumeric(p)
    p = p(:);
    if numel(p) ~= 6
        error('Numeric lqrParams must be a 6x1 vector: [qx qy qxd qyd rF rth].');
    end
    Q = diag(p(1:4));
    R = diag(p(5:6));
else
    error('lqrParams must be either a struct or a numeric vector.');
end

end

function v = local_getfield(s, name, default)
if isfield(s, name) && ~isempty(s.(name)) && isfinite(s.(name))
    v = s.(name);
else
    v = default;
end
end
