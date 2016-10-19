function outY = smoothgd(y, x, sd, maxSD)
%o = smoothgd(y, x, sd[, maxSD]) - smooth vector y using gaussian smoothing.
%The distances of the gaussian smoothing are given by the vector x.
%maxSD is the maximal distance (in stdevs) to use for smoothing.
%
%Smoothing is safe: at the ends of the vector, smoothing is done to one
%direction only.
% 
% Written by Dror Dotan, 2016

    if ~exist('maxSD', 'var')
        maxSD = 3;
    end
    
    if length(x) ~= length(y)
        error('x and y must be of the same length!');
    end
    
    outY = NaN(size(y));
    for i = 1:length(y)
        
        dx = abs(x - x(i)) / sd;
        relevantInds = dx <= maxSD;
        
        weights = zeros(size(x));
        weights(relevantInds) = gauss(dx(relevantInds), 0, 1);
        weights(relevantInds) = weights(relevantInds) / sum(weights(relevantInds));
        
        outY(i) = sum(y .* weights);
        
    end
end

