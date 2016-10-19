function f = gauss( x, meanVal, stDev )
%f = gauss( x, meanVal, stDev ) - Return the value of x in the gaussian
%distribution with the given mean and standard deviation

    p1 = -.5 * ((x - meanVal)/stDev) .^ 2;
    p2 = (stDev * sqrt(2*pi));
    f = exp(p1) ./ p2; 

end

