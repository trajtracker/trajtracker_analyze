function result = smoothw(x, weights, extrapolateEndValues)
%o = smoothw(x, weights, extrapolateEndValues) - smooth vector x using the given weights.
%
% x(i) is smoothed using x(i) with weights(1), x(i+1) and x(i-1) using
% weights(2), etc.
%
% extrapolateEndValues: a boolean flag:
%              False- Near the ends of the vector, use only the existing
%                     values (ignore "indices" beyond the end of the
%                     vector; as a result, the smoothing is not symmetric but
%                     biased towards the middle of the vector).
%              True - extrapolate the vector by duplicating x(1) and x(end)
% 
% Written by Dror Dotan, 2016

    sizeX = size(x);
    x = reshape(x, 1, length(x));
    
    nXVals = length(x);
    nWeights = length(weights);
    
    result = x * weights(1);
    
    xShiftedLeft = x;
    xShiftedRight = x;
    
    noXInfoLeft = isnan(x);  % Indicates missing xShiftedLeft values
    noXInfoRight = isnan(x); % Indicates missing xShiftedRight values
    
    totWeights = ones(size(x)) * weights(1);
    
    for i = 2:min(nWeights,nXVals)
        
        xShiftedLeft = xShiftedLeft(2:end);
        xShiftedRight = xShiftedRight(1:end-1);
        noXInfoLeft = noXInfoLeft(2:end);
        noXInfoRight = noXInfoRight(1:end-1);
        if extrapolateEndValues
            % Use the end-of-vector value as extrapolation
            xShiftedLeft = [xShiftedLeft xShiftedLeft(end)];
            xShiftedRight = [xShiftedRight(1) xShiftedRight];
            noXInfoLeft = [noXInfoLeft noXInfoLeft(end)];
            noXInfoRight = [noXInfoRight(1) noXInfoRight];
            iOr1 = 1;
        else
            iOr1 = i;
        end
        
        weightedLeft = xShiftedLeft * weights(i);
        weightedLeft(noXInfoLeft) = 0;
        result(1:(nXVals-iOr1+1)) = result(1:(nXVals-iOr1+1)) + weightedLeft;
        totWeights(1:(nXVals-iOr1+1)) = totWeights(1:(nXVals-iOr1+1)) + weights(i) .* ~noXInfoLeft;
        
        weightedRight = xShiftedRight * weights(i);
        weightedRight(noXInfoRight) = 0;
        result(iOr1:nXVals) = result(iOr1:nXVals) + weightedRight;
        totWeights(iOr1:nXVals) = totWeights(iOr1:nXVals) + weights(i) .* ~noXInfoRight;
        
    end
    
    result = result ./ totWeights;

    result = reshape(result, sizeX);
    
end

