function clearPlots()
%CLEARPLOTS 
%
global params;

for i = 1 : numel(params.plots.axesHandles)
    h = params.plots.axesHandles(i);
    cla(h);
end
