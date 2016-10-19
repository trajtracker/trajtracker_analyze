function outArray = myarrayfun(func, inArray)
% outArray = myarrayfun(func, inArray) - Similar to arrayfun(),
% but can return arrays of objects
    
    outArray = [];
    for inElem = inArray
        outArray = [outArray func(inElem)]; %#ok<AGROW>
    end

end

