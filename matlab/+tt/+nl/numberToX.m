function x = numberToX(n, axisMaxValue)
% x = numberToX(n, axisMaxValue) - Convert a number on the line to X coord.
% n can be a vector. axisMaxValue must be a scalar.

    halfAxis = axisMaxValue/2;
    x = (n - halfAxis) / halfAxis * tt.nl.MaxLogicalXValue;

end

