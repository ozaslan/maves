function setScenario(scenario)
%SETSCENARIO Store the active scenario in the simulator database.
%
%   setScenario(SCENARIO) updates the global simulator state with the
%   provided scenario struct.

global state;

if nargin < 1 || isempty(scenario)
    error('Scenario must be provided.');
end

state.scenario = scenario;

end
