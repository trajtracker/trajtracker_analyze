classdef TrajCols
% The columns in a trial's trajectory matrix
    
    methods(Static)
        
        function v = AbsTime()
            v = 1;
        end
        function v = NormTime()
            v = 2;
        end
        function v = X()
            v = 3;
        end
        function v = Y()
            v = 4;
        end
        function v = XRaw()    % Unsmoothed coordinates
            v = 5;
        end
        function v = YRaw()    % Unsmoothed coordinates
            v = 6;
        end
        function v = R()
            v = 7;
        end
        function v = Theta()
            v = 8;
        end
        function v = ImpliedEP()
            v = 9;
        end
        function v = RadialVelocity()   % d(radius)/dt
            v = 10;
        end
        function v = RadialAccel()
            v = 11;
        end
        function v = XVelocity()        % instantaneous x velocity
            v = 12;
        end
        function v = XAcceleration()    % instantaneous acceleration
            v = 13;
        end
        function v = AngularVelocity()  % d(theta)/dt
            v = 14;
        end
        function v = YVelocity()        % instantaneous y velocity
            v = 15;
        end
        function v = YAcceleration()
            v = 16;
        end
        function v = NUM_COLS() 
            v = 16;
        end

        function col = colByName(colName)
            [~, colNumByName ] = TrajCols.getAllCols();
            if isfield(colNumByName, colName)
                col = colNumByName.(colName);
            else
                col = NaN;
            end
        end
        
        
        function [nameByColNum, colNumByName ,codes] = getAllCols()
            nameByColNum = {};
            colNumByName = struct;
            codes = [];
            methods = meta.class.fromName('TrajCols').MethodList;
            for i = 1:length(methods)
                method = methods(i);
                if (method.Static && isempty(method.InputNames) && length(method.OutputNames) == 1 && strcmp(method.OutputNames{1}, 'v'))
                    v = eval(strcat('TrajCols.', method.Name));
                    nameByColNum{v} = method.Name; %#ok<AGROW>
                    colNumByName.(method.Name) = v;
                    codes = [codes v]; %#ok<AGROW>
                end
            end
        end
        
        %----------------------------------------------------
        function colName = getColName(colNum)
            nameByColNum = TrajCols.getAllCols();
            if colNum >= 1 && colNum <= length(nameByColNum)
                colName = nameByColNum{colNum};
            else
                colName = 'N/A';
            end
        end
        
    end
end
