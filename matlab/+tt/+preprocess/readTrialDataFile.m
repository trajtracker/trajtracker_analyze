function [trialData, extraColNames] = readTrialDataFile(filename, varargin)
%[trialData, extraColNames] = readTrialDataFile(filename)
% Read the trials file
% 
% Optional args:
% MandatoryCols <list>/'all': column codes that must appear in the file
% OutFormat matrix/struct/cell - if you use matrix/cell, you must use the
%                           "ReadCols" flag. 
%                           For "matrix", specify only numeric columns.
% ReadCols <cell-array>: specify a list of column names to read
% 
% Output args:
% trialDataFamiliar: matrix with the trial data, with columns organized by
%            the standard order (i.e., column#1 is subsession, etc.).
%            Missing columns have value 0.
% loadedCols: Numbers of default columns that were found in the file.
% trialDataExtra: Matrix with trial data - only unfamiliar columns.
% extraColNames: The names of the unfamiliar columns that were found in the file (cell array).
    
    [mandatoryCols, readColNames, outFormat] = parseArgs(varargin);
    
    % Create mapping of columns in files
    [fileColNames, fileColNamesToNums] = readHeaderLine(filename);
    
    %-- Validate mandatory columns
    missingColNames = mandatoryCols(arrayfun(@(c)~ismember(c{1}, fileColNames), lower(mandatoryCols)));
    if ~isempty(missingColNames)
        error('Error loading trials file %s: some columns (%s) are missing', filename, join(',', missingColNames));
    end
    
    familiarColNames = lower(tt.preprocess.trialFileMandatoryColumns('ALL'));
    extraColNames = fileColNames(arrayfun(@(c)~ismember(c{1}, familiarColNames), lower(fileColNames)));
    
    switch(lower(outFormat))
        case {'m', 'matrix'}
            trialData = readTrialDataMatrix(filename, fileColNames, fileColNamesToNums, readColNames);
            
        case {'c', 'cell'}
            trialData = readTrialDataCell(filename, fileColNames, fileColNamesToNums, readColNames);
            
        case {'s', 'struct'}
            trialData = readTrialDataStruct(filename, fileColNames, fileColNamesToNums, readColNames);
            
        otherwise
            error('Unsupported output format "%s"', outFormat);
    end
    
    %----------------------------------------------------
    function trialData = readTrialDataCell(filename, fileColNames, fileColNamesToNums, readCols)
        
        if isempty(readCols)
            error('When requesting for output as a cell matrix, you must use the "ReadCols" flag!');
        end
        
        [trialData, numericCsvData, isNumericField] = readTrialDataToCellMatrix(filename, fileColNames, fileColNamesToNums, readCols);
        for iFld = find(isNumericField)
            for row = 1:size(trialData, 1)
                trialData{row,iFld} = numericCsvData(row, iFld);
            end
        end
    end

    %----------------------------------------------------
    function trialData = readTrialDataMatrix(filename, fileColNames, fileColNamesToNums, readCols)
        
        if isempty(readCols)
            error('When requesting for output as a matrix, you must use the "ReadCols" flag!');
        end
        
        [~, numericCsvData, isNumericField, readCols] = readTrialDataToCellMatrix(filename, fileColNames, fileColNamesToNums, readCols);
        if (sum(~isNumericField) > 0)
            nonNumericFields = join(',', readCols(~isNumericField));
            error('The following fields in file %s are not numeric so they cannot be read into a matrix format: %s', filename, nonNumericFields);
        end
        trialData = numericCsvData;
        
    end

    %----------------------------------------------------
    function trialData = readTrialDataStruct(filename, fileColNames, fileColNamesToNums, readCols)
        
        [csvData, numericCsvData, isNumericField, readCols] = readTrialDataToCellMatrix(filename, fileColNames, fileColNamesToNums, readCols);
        
        nRows = size(csvData, 1);
        
        % Convert to struct
        trialData = [];
        for row = 1:nRows
            
            lineData = struct;
            for iFld = 1:length(readCols)
                if isNumericField(iFld)
                    lineData.(readCols{iFld}) = numericCsvData(row, iFld);
                else
                    lineData.(readCols{iFld}) = csvData{row, iFld};
                end
            end
            
            trialData = [trialData lineData]; %#ok<AGROW>
        end
    end

    %----------------------------------------------------
    function [csvData, numericCsvData, isNumericField, readCols] = readTrialDataToCellMatrix(filename, fileColNames, fileColNamesToNums, readCols)
        
        nFileCols = length(fileColNames);
        if isempty(readCols)
            readCols = fileColNames;
        end
        
        % Get numbers of columns to read
        readCols = lower(readCols);
        readColNums = arrayfun(@(c)fileColNamesToNums.(c{1}), readCols);
        
        fh = fopen(filename, 'r');
        fgetl(fh); % skip first line
        lineNum = 1;
        
        csvData = {};
        
        % Read data into a cell array
        try
            while ~feof(fh)
                % Read line
                line = fgetl(fh);
                lineNum = lineNum+1;
                fields = regexp(line, ',', 'split');
                if (length(fields) ~= nFileCols)
                    error('Error in line #%d in %s: expecting %d fields, got %d', lineNum, filename, nFileCols, length(fields));
                end

                csvData = [csvData; fields(readColNums)]; %#ok<AGROW>
            end
            
            fclose(fh);
        catch e
            fclose(fh);
            rethrow(e);
        end
        
        nRows = size(csvData, 1);
        numericCsvData = NaN(size(csvData));
        isNumericField = NaN(1, length(readColNums));
        
        % Convert relevant columns to numeric (if possible)
        for iFld = 1:length(readColNums)
            numericCsvData(:, iFld) = arrayfun(@(r)str2double(csvData{r,iFld}), 1:nRows);
            explicitNAN = arrayfun(@(r)strcmpi(csvData{r,iFld}, 'nan'), (1:nRows)');
            notNumeric = isnan(numericCsvData(:, iFld)) & ~explicitNAN;
            isNumericField(iFld) = sum(notNumeric) == 0;
        end
        
        % Force certain columns to numeric
        for ccol = {'endpoint'}
            colName = ccol{1};
            if ~ismember(colName, fileColNames)
                continue
            end
            colNum = fileColNamesToNums.(colName);
            isNumericField(colNum) = true;
            numericCsvData(:, colNum) = arrayfun(@(value)str2double(value{1}), csvData(:, colNum));
        end
        
    end

    %----------------------------------------------------
    function [colNames, colNamesToNums] = readHeaderLine(filename)
        
        fh = fopen(filename);
        headerLine = lower(fgetl(fh));
        fclose(fh);
        
        colNames = regexp(headerLine, ',', 'split');
        colNamesToNums = struct;
        for i = 1:length(colNames)
            colNamesToNums.(lower(tt.preprocess.normalizeTrialsFileColumnName(colNames{i}))) = i;
        end
        
    end

    %----------------------------------------------------
    function [mandatoryCols, readCols, outFormat] = parseArgs(args)
        
        mandatoryCols = {};
        readCols = {};
        outFormat = 'struct';
        
        args = stripArgs(args);
        
        while ~isempty(args)
            switch(lower(args{1}))
                case 'mandatorycols'
                    mandatoryCols = args{2};
                    args = args(2:end);
                    if strcmpi(mandatoryCols, 'all')
                        mandatoryCols = familiarColNums;
                    end
                    
                case 'outformat'
                    outFormat = args{2};
                    args = args(2:end);
                    
                case 'readcols'
                    readCols = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            args = stripArgs(args(2:end));
        end
        
        mandatoryCols = arrayfun(@(m){lower(m{1})}, mandatoryCols);
        
    end

end

