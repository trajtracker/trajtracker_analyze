function colName = normalizeTrialsFileColumnName(colName)
    colName = strrep(colName, '.', '_');
    colName = strrep(colName, '%', '_pcnt');
end
