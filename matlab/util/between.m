function b = between(val, minVal, maxVal)
%BETWEEN(val,bound1,bound2) - check if value is between the two bounds

    if (minVal > maxVal)
        tmp = minVal;
        minVal = maxVal;
        maxVal = tmp;
    end
    
    b = (val >= minVal) & (val <= maxVal);

end

