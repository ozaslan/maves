function [freq, period] = getSimFrequency()
%GETSIMFREQUENCY This function returns the sim. frequency.
%   
%   This function retrieves the simulator frequency from the simulator
%   database and returns its along with the simulator step period in
%   seconds.

global params;

freq   = params.sim.freq;
period = 1 / freq;

