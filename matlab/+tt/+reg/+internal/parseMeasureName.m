function [measureName, measureArgs] = parseMeasureName(measureExpr)
%[predName, predArgs] = parseMeasureName(expr) -
% Parse a string describing a measure name - into name + arguments

    elems = regexp(measureExpr, '::', 'split');
    if iscell(elems{1})
        elems = elems{1};
    end
    measureName = elems{1};
    measureArgs = elems(2:end);

end

