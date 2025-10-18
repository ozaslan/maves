# Solution Trajectory and Control Modules

This document summarizes the reference implementations provided in the
`soln` directory. The files define the nominal controller and a collection of
trajectory generators used by the planar quadrotor simulation. Each function
shares a common interface designed to plug into the core simulation helpers in
`matlab/utils` and `matlab/core`.

## `controller.m`

### Purpose
Implements the reference feedback law that converts the current vehicle
state and desired trajectory into actionable control inputs. The controller is
responsible for tracking the target motion profile defined by the trajectory
modules below.

### Inputs
- `t` *(scalar)*: Current simulation timestamp.
- `s` *(8×1 vector)*: Full quadrotor state in the format returned by
  `getStateVector()`: `[x; y; th; xdot; ydot; thdot; xddot; yddot]`.

### Outputs
- `u` *(2×1 vector)*: Control input vector `[F; th_des]` containing the total
  thrust to apply and the desired pitch angle.

### Behavior
1. Validates the shapes of `t` and `s`.
2. Retrieves gravity (`g`) and vehicle mass (`m`) via helper functions in
   `matlab/utils`.
3. Queries the currently active trajectory through `evalTrajectory(t, s)` to
   obtain desired positions, velocities, and accelerations.
4. Computes the desired horizontal acceleration with a PD term
   `rddot = sT(7:8) + kd*(sT(4:5) - s(4:5)) + kp*(sT(1:2) - s(1:2))`, where
   `kp` and `kd` are tuned gains.
5. Converts the acceleration demand into a desired pitch (`th`) and thrust (`F`).
6. Returns the control command vector `[F; th]`.

The controller therefore closes the loop between the simulated dynamics and the
planned motion, enabling trajectory tracking.

## Trajectory Generators
All trajectory generators share a consistent signature:
`trajName(t, s, ...) -> sT` where `sT` is a 9×1 vector containing desired
states up to second derivatives:
`[x; y; th; xdot; ydot; thdot; xddot; yddot; thddot]`.

The extra derivatives support feed-forward terms in the controller.

### `trajHover.m`
- **Purpose**: Command the quadrotor to hold position at a fixed point `r`.
- **Inputs**:
  - `t`: Current time (not used in the solution but kept for interface
    consistency).
  - `s`: Current vehicle state (unused here but allows the function to inspect
    the state if needed).
  - `r` *(2×1 vector)*: Target hover position `[x; y]`.
- **Output**: Desired state vector with position equal to `r`, zero yaw, and
  zero velocity/acceleration terms to keep the vehicle stationary.

### `trajLine.m`
- **Purpose**: Generate a straight-line motion from `posStart` to `posEnd`
  over duration `tEnd` with trapezoidal velocity shaping.
- **Inputs**: `t`, `s`, start position `posStart`, end position `posEnd`, and
  total time `tEnd`.
- **Output**: Desired state vector following the line. Position ramps linearly
  between the endpoints. Velocity follows a trapezoidal profile with a ramp-up
  and ramp-down phase defined by `margin`, and zero beyond `tEnd`. Orientation
  and higher derivatives remain zero.

### `trajCircle.m`
- **Purpose**: Trace a circular path centered at `p` with radius `r`, completed
  in `tEnd` seconds.
- **Inputs**: `t`, `s`, center `p`, radius `r`, completion time `tEnd`.
- **Output**: Desired position on the circle with corresponding velocity and
  acceleration derived analytically. After `tEnd` the state freezes at the
  final point. Yaw and its derivatives are maintained at zero.

### `trajDiamond.m`
- **Purpose**: Traverse a diamond-shaped closed loop through four waypoints
  (`p0`→`p1`→`p2`→`p3`→`p0`) within `tEnd` seconds.
- **Inputs**: `t`, `s`, waypoint positions `p0`–`p3`, and total duration
  `tEnd`.
- **Output**: Desired state vector obtained by chaining `trajLine` segments.
  Segment durations are apportioned proportionally to edge lengths, and time
  is clamped to `tEnd` to avoid overshoot.

## Integration with the Simulation
1. A high-level mission selects one of the trajectory generators and calls it
   every simulation step to provide the desired state `sT`.
2. The controller ingests `sT` along with the current state `s` to compute
   thrust and attitude commands.
3. These commands are applied to the dynamics model in `matlab/core`, closing
   the loop and allowing evaluation of control performance on canonical motion
   patterns (hover, line, circle, diamond).

The modular structure makes it straightforward to author new trajectories or
swap control strategies while preserving interfaces expected by the simulator.
