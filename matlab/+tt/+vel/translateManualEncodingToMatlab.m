function data= translateManualEncodingToMatlab(inCSVFile, outMFile, varargin)
%translateManualEncodingToMatlab() - Read the CSV file that was created
% by <a href="matlab:help tt.vel.encodeVelocityOnsetManually">tt.vel.encodeVelocityOnsetManually</a>
% and translate it into a matlab script that saves this onset information
% to trials.
% 
% Optional arguments:
% CondNames <cell-array>: Matlab variable names for each of the conditions
%                         reviewed in the encoding function.
% DivideBy <factor>: All onset times in the CSV file will be divided by
%                    this factor.


    [condNames, divideTimesBy] = parseArgs(varargin);

    data = readEncodings(inCSVFile);
    data = transformEncodings(data, divideTimesBy, condNames);
    saveScript(data, outMFile);

    %-------------------------------------------
    function data = readEncodings(filename)
        
        data = [];
        
        fp = fopen(filename, 'r');
        if fp < 0
            error('Failed opening %s', filename);
        end

        %-- Read header line
        header = fgetl(fp);
        fields = regexp(header, ',', 'split');
        fields = arrayfun(@(f){lower(f{1})}, fields);
        
        try

            while ~feof(fp)
                line = fgetl(fp);
                elems = regexp(line, ',', 'split');
                
                entry = struct;
                for i = 1:length(fields)
                    entry.(fields{i}) = elems{i};
                end
                
                data = [data entry]; %#ok<AGROW>
            end

        catch e
            fclose(fp);
            rethrow(e);
        end

        fclose(fp);

    end    
    
    %-------------------------------------------
    function data = transformEncodings(data, divideTimesBy, condNames)
        
        for i = 1:length(data)
            entry = data(i);
            
            if strcmpi(entry.onset, 'onset')
                entry.onset = '[]';
            elseif ~isnan(divideTimesBy)
                entry.onset = num2str(str2double(entry.onset) / divideTimesBy);
            end

            if strcmpi(entry.peak, 'peak')
                entry.peak = '[]';
            elseif ~isnan(divideTimesBy)
                entry.peak = num2str(str2double(entry.peak) / divideTimesBy);
            end

            if ~isempty(condNames)
                re = regexp(entry.condition, '^cond(\d+)$', 'tokens');
                if re
                    cond = str2double(re{1});
                    entry.condition = condNames{cond};
                end
            end
            
            data(i) = entry;
        end
        
    end

    %-------------------------------------------
    function saveScript(data, filename)
        
        fp = fopen(filename, 'w');
        if fp < 0
            error('Failed opening %s', filename);
        end
        
        for entry = data
            fprintf(fp, 'tt.vel.setOnsetVelocityTime(''%s'', ''%s'', %s, %s, %s, %s, %s, %s);\n', ...
                entry.condition, entry.subject, entry.trialnum, ...
                entry.onset, entry.peak, entry.wrongdir, entry.changeofmind, entry.override);
        end
        
        fclose(fp);
    end

    %-------------------------------------------
    function [condNames, divideTimesBy] = parseArgs(args)
        
        condNames = {};
        divideTimesBy = NaN;

        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'x'
                    x = args{2};
                    args = args(2:end);

                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

    end


end

