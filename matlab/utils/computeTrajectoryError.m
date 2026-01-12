function [tAligned, errorMag, rmse, maxError] = computeTrajectoryError( ...
    tActual, actualPos, tRef, refPos)
%COMPUTETRAJECTORYERROR  Position error metrics between actual and reference.
%   [TALIGNED, ERRORMAG, RMSE, MAXERROR] = COMPUTETRAJECTORYERROR(TACTUAL,
%   ACTUALPOS, TREF, REFPOS) interpolates the reference position REFPOS onto
%   the ACTUALPOS time stamps and returns the position error magnitude over
%   the overlapping time window along with RMSE and maximum error metrics.

rmse = NaN;
maxError = NaN;
tAligned = [];
errorMag = [];

if isempty(tActual) || isempty(actualPos) || isempty(tRef) || isempty(refPos)
    return;
end

tActual = tActual(:)';
tRef = tRef(:)';

if size(actualPos, 2) ~= numel(tActual)
    return;
end

if size(refPos, 2) ~= numel(tRef)
    return;
end

tMin = max(min(tActual), min(tRef));
tMax = min(max(tActual), max(tRef));

if tMax <= tMin
    return;
end

mask = (tActual >= tMin) & (tActual <= tMax);

if nnz(mask) < 2
    return;
end

refInterpX = interp1(tRef, refPos(1, :), tActual(mask), 'linear');
refInterpY = interp1(tRef, refPos(2, :), tActual(mask), 'linear');

if any(isnan(refInterpX)) || any(isnan(refInterpY))
    return;
end

actualAligned = actualPos(:, mask);
errorVec = actualAligned - [refInterpX; refInterpY];
errorMag = sqrt(sum(errorVec .^ 2, 1));
tAligned = tActual(mask);

rmse = sqrt(mean(errorMag .^ 2));
maxError = max(errorMag);

end
