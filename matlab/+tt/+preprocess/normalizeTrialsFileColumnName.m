function colName = normalizeTrialsFileColumnName(colName)
    if iscell(colName)
        colName = arrayfun(@(c){tt.preprocess.normalizeTrialsFileColumnName(c{1})}, colName);
        return
    end
    colName = strrep(colName, '.', '_');
    colName = strrep(colName, '%', '_pcnt');
end
