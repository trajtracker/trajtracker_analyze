function result = getTrajValue(trials, rowNum, colNum)
%v = getTrajValue(trials, row, col) - Get trajectory value for multiple trials. 
% This is a safe function:
% - Supports negative row numbers (means end-X)
% - Support row numbers that exceed the trajectory matrix (get end-of-matrix
%   values)

    trajNRows = arrayfun(@(t)size(t.Trajectory, 1), trials);
    rowNumPerTrial = min(abs(rowNum), trajNRows);
    if rowNum > 0
        result = arrayfun(@(i)trials(i).Trajectory(rowNumPerTrial(i), colNum), 1:length(trials))';
    else
        result = arrayfun(@(i)trials(i).Trajectory(end-rowNumPerTrial(i), colNum), 1:length(trials))';
    end

end

