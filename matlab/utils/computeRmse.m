function rmse = computeRmse(tActual, actual, tRef, ref)
%COMPUTERMSE  Root-mean-square error between two time series.
%   RMSE = COMPUTERMSE(TACTUAL, ACTUAL, TREF, REF) computes the
%   root-mean-square error (RMSE) between an actual signal ACTUAL sampled at
%   times TACTUAL and a reference signal REF sampled at times TREF.
%
%   Inputs
%   ------
%   tActual : Vector of monotonically increasing time stamps associated with
%             the ACTUAL samples. The vector is reshaped into a column
%             internally. Units are seconds.
%   actual  : Vector containing the measured signal values. The vector is
%             reshaped into a column internally and must have the same
%             number of elements as TACTUAL.
%   tRef    : Vector of monotonically increasing time stamps for the
%             reference signal samples REF. The vector is reshaped into a
%             column internally. Units are seconds.
%   ref     : Vector containing the reference signal values. The vector is
%             reshaped into a column internally.
%
%   Output
%   -------
%   rmse    : Scalar value equal to the root-mean-square error between the
%             actual and reference signals evaluated over the overlapping
%             time window. NaN is returned if the inputs do not provide a
%             valid overlapping window or contain insufficient samples for a
%             meaningful comparison.
%
%   The reference signal is linearly interpolated onto the time stamps of
%   the actual signal prior to the RMSE computation so that both vectors are
%   aligned.
%
%   See also INTERP1, MEAN, SQRT.

if isempty(actual) || isempty(ref) || isempty(tActual) || isempty(tRef)
    rmse = NaN;
    return;
end

tActual = tActual(:);
actual  = actual(:);
tRef    = tRef(:);
ref     = ref(:);

if numel(actual) ~= numel(tActual)
    rmse = NaN;
    return;
end

% Restrict to the overlapping time window and interpolate the reference
% onto the actual time stamps to ensure alignment.
tMin = max(min(tActual), min(tRef));
tMax = min(max(tActual), max(tRef));

if tMax <= tMin
    rmse = NaN;
    return;
end

mask = (tActual >= tMin) & (tActual <= tMax);

if nnz(mask) < 1
    rmse = NaN;
    return;
end

refInterp = interp1(tRef, ref, tActual(mask), 'linear');

if any(isnan(refInterp))
    rmse = NaN;
    return;
end

diffs = actual(mask) - refInterp;
rmse = sqrt(mean(diffs .^ 2));

end
