function n = xToNumber(x, axisMaxValue)
%n = xToNumber(x, axisMaxValue) - Convert x coord to a number on the line
% x can be a vector. axisMaxValue must be a scalar.

    n = x / tt.nl.MaxLogicalXValue * axisMaxValue/2 + axisMaxValue/2;

end

