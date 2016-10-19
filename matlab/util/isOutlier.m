function result = isOutlier(v, ratio)
% o = isOutlier(v[, ratio]) - Find outliers in the array "v"
% Outlier is defined as a value exceeding the inter-quartile range (Q3-Q1)
% by more than ratio (default ratio = 1.5).
% 
% 'o' is an array indicating, per entry in 'v', whether it's an outlier:
%    0 = not outlier
%    1 = upward outlier
%    -1 = downward outlier

    if ~ exist('ratio', 'var')
        ratio = 1.5;
    end
    
    Q1 = prctile(v, 25);
    Q3 = prctile(v, 75);
    interQuartileRange = Q3-Q1;
    minBound = Q1 - interQuartileRange * ratio;
    maxBound = Q3 + interQuartileRange * ratio;

    result = logical((v>maxBound) - (v<minBound));
end
