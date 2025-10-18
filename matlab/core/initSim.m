function initSim()

global state;

state = [];

state.sim.wallStamp    = tic;
state.sim.stamp        = 0;
state.sim.step         = 0;
state.qcopter.pose     = [0; 0; 0];
state.qcopter.vel      = [0; 0; 0];
state.qcopter.w        = [1000; 1000];
state.qcopter.traj     = [];
state.qcopter.trajHist = [];
state.qcopter.forces   = [];
state.qcopter.cmdHist  = [];
state.qcopter.cmd      = struct('stamp', [], ...
                                'thDes', [], ...
                                'thDotDes', [], ...
                                'forces', []);
