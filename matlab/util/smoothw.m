function result = smoothw(x, weights, endValuesPolicy)
%o = smoothw(x, weights, endValuesPolicy) - smooth vector x using the given weights.
%
% x(i) is smoothed using x(i) with weights(1), x(i+1) and x(i-1) using
% weights(2), etc.
%
% endValuesPolicy:
%    'simple' - Near the ends of the vector, use only the existing
%               values (ignore "indices" beyond the end of the
%               vector; as a result, the smoothing is not symmetric but
%               biased towards the middle of the vector).
%    'extrapolate' - extrapolate the vector by duplicating x(1) and x(end)
%    'symmetric' - smooth any point only based on symmetric
%                  points around it. At the end of the vector,
%                  when data becomes unavailable on one side,
%                  crop symmetric data from the othe side too.

    [~, p] = ismember(lower(endValuesPolicy), {'simple', 'extrapolate', 'symmetric'});
    if p == 0, error('Invalid "endValues" argument: %s', endValuesPolicy); end
    endValuesPolicy = p;
    
    sizeX = size(x);
    x = reshape(x, 1, length(x));
    
    nXVals = length(x);
    nWeights = length(weights);
    
    result = x * weights(1);
    
    % The loop iterates through all weights (except weights(1), which was
    % already accumulated) and accumulates them one at a time.
    
    xShiftedLeft = x;
    xShiftedRight = x;
    
    noXInfoLeft = isnan(x);  % Indicates missing xShiftedLeft values
    noXInfoRight = isnan(x); % Indicates missing xShiftedRight values
    
    totWeights = ones(size(x)) * weights(1);
    
    for i = 2:min(nWeights,nXVals)
        
        switch(endValuesPolicy)
            case 1
                % Simple smoothing, no restrictions
                xShiftedLeft = xShiftedLeft(2:end);
                noXInfoLeft = noXInfoLeft(2:end);
                xShiftedRight = xShiftedRight(1:end-1);
                noXInfoRight = noXInfoRight(1:end-1);
        
            case 2
                % Use the end-of-vector value as extrapolation
                xShiftedLeft = [xShiftedLeft(2:end) xShiftedLeft(end)];
                noXInfoLeft = [noXInfoLeft(2:end) noXInfoLeft(end)];
                xShiftedRight = [xShiftedRight(1) xShiftedRight(1:end-1)];
                noXInfoRight = [noXInfoRight(1) noXInfoRight(1:end-1)];

            case 3
                % Keep symmetry: When a value is missing on one side, ignore the
                % corresponding value on the other side.
                xShiftedLeft = [xShiftedLeft(2:end) NaN];
                xShiftedRight = [NaN xShiftedRight(1:end-1)];
                
                noXInfoLeft = isnan(xShiftedLeft) | isnan(xShiftedRight);
                noXInfoRight = noXInfoLeft;
        end
        
        weightedLeft = xShiftedLeft * weights(i);
        weightedLeft(noXInfoLeft) = 0;
        result = result + weightedLeft;
        totWeights = totWeights + weights(i) .* ~noXInfoLeft;
        
        weightedRight = xShiftedRight * weights(i);
        weightedRight(noXInfoRight) = 0;
        result = result + weightedRight;
        totWeights = totWeights + weights(i) .* ~noXInfoRight;
        
    end
    
    result = result ./ totWeights;

    result = reshape(result, sizeX);
    
end

