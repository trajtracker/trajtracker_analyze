function r = nlLog(x,maxVal)
%r = NLLOG(x,maxVal) - Create a log function, linearly rescaled to a given range
%

    r = log(x+1) / log(maxVal+1) * maxVal;
    
end
