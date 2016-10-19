function d = cohend(x)
% d = cohend(x) - Calculate Cohen's d for a t-test
% x - matrix with 2 columns
% 
% Written by Dror Dotan, 2016

    if (size(x,2) == 2)
        
        deltaMeans = mean(x(:,1)) - mean(x(:,2));
        sd = std(x(:,1) - x(:,2));
        d = deltaMeans / sd;
        
    elseif (size(x,1) ~= 1 && size(x,2) ~= 1)
        error('Invalid x size');
    else
        d = mean(x) / std(x);
    end

end

