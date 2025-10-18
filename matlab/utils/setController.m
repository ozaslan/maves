function setController(hCtrl, ctrlParams)
%SETCONTROLLER  Use this function to set controller
%
%   The first input must be a handle to a control function.  The optional
%   second input bundles parameters that will be forwarded to the
%   controller every time it is evaluated.  The input - output
%   specifications of a control function are given in the template
%   function 'controller'.

global params;

if nargin < 2
    ctrlParams = [];
elseif ~(isnumeric(ctrlParams) && isvector(ctrlParams) && ...
        (numel(ctrlParams) == 3 || numel(ctrlParams) == 4))
    error(['Controller parameters must be provided as a numeric vector ', ...
        'with three (PID) or four (PID + integral limit) elements.']);
else
    ctrlParams = ctrlParams(:);
end

params.controller = hCtrl;
params.controllerParams = ctrlParams;

