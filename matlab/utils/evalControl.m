function u = evalControl(t, s)
%EVALCONTROL This calls the controller function registered by user
%
%   This function retrieves the handle to the contoller function 
%   provided by the user through 'setController()' and relays its 
%   output.

global params;

hCtrl = params.controller;

if isfield(params, 'controllerParams') && ~isempty(params.controllerParams)
    u = hCtrl(t, s, params.controllerParams);
else
    u = hCtrl(t, s);
end

