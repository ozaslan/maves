# MAVES: MATLAB Aerial Vehicle Educational Simulator

MAVES is a MATLAB-based, planar vertical take-off and landing (VTOL) sandbox that lets students design guidance and control algorithms for a quadcopter.
The `matlab/runsim.m` script wires together the core simulator, helper utilities, and either the provided starter code or an instructor solution before looping the physics and visualization updates that drive the experience.【F:matlab/runsim.m†L1-L84】

## Repository layout
- `matlab/core` – physics, state management, and visualization routines that initialize the simulator, integrate the dynamics, and update plots each frame.【F:matlab/core/initialize.m†L1-L12】【F:matlab/core/updatePhysics.m†L1-L40】
- `matlab/utils` – helper utilities for registering controllers, selecting arenas, and querying simulator parameters from anywhere in the workspace.【F:matlab/utils/setController.m†L1-L11】【F:matlab/utils/setTrajectoryGenerator.m†L1-L12】【F:matlab/utils/setArena.m†L1-L21】
- `matlab/studentCode` – templates where learners implement their controller and trajectory generators, ready to be activated from `runsim` for testing.【F:matlab/studentCode/controller.m†L1-L18】【F:matlab/studentCode/trajCircle.m†L1-L27】
- `matlab/soln` – a worked solution set that demonstrates one possible implementation of the required logic.【F:matlab/runsim.m†L11-L29】
- `matlab/arenas` – text-based arena descriptions that constrain the vehicle’s motion and obstacle layout.【F:matlab/utils/setArena.m†L1-L21】

## Running the simulator
1. Open MATLAB and `cd` into the `matlab` folder.
2. Choose the implementation you want to exercise by setting `activeSolution` to either `'student'` or `'solution'` near the top of `runsim.m`; the script manages the MATLAB path so that only the selected submission is active.【F:matlab/runsim.m†L5-L31】
3. Pick a trajectory generator by calling `setTrajectoryGenerator` with the handle and parameters you want. Sample calls are provided for hovering, line, diamond, and circular paths.【F:matlab/runsim.m†L55-L64】
4. Register your controller with `setController(@controller)`; the default starter template simply returns zeros until you flesh it out.【F:matlab/runsim.m†L66-L70】【F:matlab/studentCode/controller.m†L1-L18】
5. Run the script. The main loop advances the dynamics, updates the visualization, and sleeps to maintain the configured simulation rate until the vehicle either completes its task or leaves the arena.【F:matlab/runsim.m†L71-L84】【F:matlab/core/updatePhysics.m†L1-L40】
   Use `setVisualizationMode('deferred')` if you prefer to run the physics as quickly as possible and only draw the final plots after the simulation stops; the default `'live'` mode keeps the original frame-by-frame updates.【F:matlab/runsim.m†L66-L88】【F:matlab/utils/setVisualizationMode.m†L1-L27】【F:matlab/core/updateVisuals.m†L1-L26】
   Enable capture with `setCaptureMode('save')` to record the arena figure while you run the simulation. In live mode this writes `maves_video_<timestamp>.mp4`; in deferred mode the final frame is exported as `maves_image_<timestamp>.png`. Use `'none'` to leave nothing behind.【F:matlab/runsim.m†L88-L93】【F:matlab/utils/setCaptureMode.m†L1-L57】【F:matlab/core/updateVisuals.m†L92-L137】

## How the simulation works
- **Initialization pipeline.** `initialize()` orchestrates parameter setup, arena configuration, state resets, and plot creation before every run.【F:matlab/runsim.m†L33-L35】【F:matlab/core/initialize.m†L1-L12】
- **Physics stepping.** Each call to `updatePhysics()` pulls the active trajectory generator and controller, integrates the coupled rigid-body and motor dynamics with `ode45`, and writes the updated state back to the simulator database.【F:matlab/core/updatePhysics.m†L1-L40】
- **Status monitoring.** `checkStatus()` stops the simulation if the quadcopter exits the arena, collides, or successfully hovers at the goal position, using the arena limits and recent motion history to decide.【F:matlab/runsim.m†L71-L84】【F:matlab/core/checkStatus.m†L1-L36】
- **Arena management.** `setArena()` looks up arena definitions in `matlab/arenas`, and helpers like `getArenaLimits()` expose the configured boundaries to controllers and monitors.【F:matlab/runsim.m†L36-L38】【F:matlab/utils/setArena.m†L1-L21】【F:matlab/utils/getArenaLimits.m†L1-L8】

## Extending MAVES
- Implement new controllers by editing `matlab/studentCode/controller.m`. Use utilities such as `evalTrajectory`, `evalControl`, and `getStateVector` to compute thrust and attitude commands that stabilize your vehicle.【F:matlab/studentCode/controller.m†L1-L18】【F:matlab/utils/setController.m†L1-L11】【F:matlab/utils/evalTrajectory.m†L1-L12】【F:matlab/utils/evalControl.m†L1-L11】【F:matlab/utils/getStateVector.m†L1-L18】
- Design alternative reference motions in the trajectory templates (hover, line, diamond, circle) or add new generator functions that follow the same signature used by `setTrajectoryGenerator`.【F:matlab/runsim.m†L55-L64】【F:matlab/utils/setTrajectoryGenerator.m†L1-L12】【F:matlab/studentCode/trajCircle.m†L1-L27】
- Customize testing scenarios by supplying additional arena files under `matlab/arenas` and selecting them via `setArena('name')`. Controllers can query the current limits with `getArenaLimits()` to stay inside the course.【F:matlab/utils/setArena.m†L1-L21】【F:matlab/utils/getArenaLimits.m†L1-L8】

With these building blocks, MAVES provides a compact environment for experimenting with VTOL guidance, navigation, and control strategies entirely within MATLAB.
