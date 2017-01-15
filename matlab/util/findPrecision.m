function p = findPrecision(x, maxPrecision)
% prec = findPrecision(x[, max]) - find the decimal precision of a number.
% The optional MAX argument specifies a maximal precision to look for
% (default: 20).
% 
% Written by Dror Dotan, 2016

    if ~exist('maxPrecision', 'var')
        maxPrecision = 20;
    end
    
    if isempty(x)
        p = 0;
    else
        tens = (10 .^ (0:maxPrecision));
        p = max(arrayfun(@(xx)findPrecisionForOneNumber(xx, tens), x)) - 1;
    end

    %-------------------------------------------
    function prec = findPrecisionForOneNumber(n, tens)
        if abs(n) < 10e-20
            %-- n is 0
            prec = 0;
            return;
        end
        tmp = abs(n) .* tens;
        prec = find(tmp >= 1 & abs(tmp-round(tmp)) < .0001, 1);
        if isempty(prec)
            prec = maxPrecision;
        end
    end
    
end

