function [o,weights] = smoothg(x, sd, smoothRange, endValuesPolicy)
%o = smoothg(x, sd[, smoothRange]) - Gaussian smoothing of vector x:
% x(i) is smoothed using adjacent entries according to gaussian
% distribution: x(i) gets the maximal weight; the weight of x(i+n) and
% x(i-n) is determined by the Gaussian value of n/sd.
%
% For any x(i), the sum of smoothing weights is set to 1.
% Note that the values used for smoothing reach only the end of the vector.
% As a result, at the ends of the vector the smoothing is not symmetric but
% biased towards the middle of the vector.
%
% Arguments:
% sd - the standard deviation of gauss distribution
% smoothRange - maximal distance to consider when smoothing (specified as
%               the number of indices in the vector x). Default = 3*SD.
% endValuesPolicy - See <a href="matlab:help smoothw">smoothw</a>

    if ~exist('smoothRange', 'var') || isnan(smoothRange)
        smoothRange = sd*3;
    end
    if ~exist('endValuesPolicy', 'var')
        endValuesPolicy = 'extrapolate';
    end
    
    if (sd == 0)
        o = x;
        weights = [];
    else
        weights = gauss(0:smoothRange, 0, sd);
        o = smoothw(x, weights, endValuesPolicy);
    end
    

end

