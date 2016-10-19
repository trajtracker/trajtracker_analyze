%===============================================================
%
%  TrajCols - Trajectory columns
%
% This class defines the column numbers in the trajectory matrix.
%
%===============================================================
classdef TrajCols
    
    methods(Static)
        
        function v = AbsTime()
            v = 1;
        end
        function v = RelativeTime()
            v = 2;
        end
        function v = X()
            v = 3;
        end
        function v = Y()
            v = 4;
        end
        function v = XRelative() % The X value, relatively to the starting position
            v = 5;
        end
        function v = XClean()    % The X value, cleaned from the initial-direction deviation
            v = 6;
        end
        function v = R()
            v = 7;
        end
        function v = InstTheta()
            v = 8;
        end
        function v = InstImpliedEP() % based on dx/dy
            v = 9;
        end
        function v = RadialVelocity()
            v = 10;
        end
        function v = RadialAccel()
            v = 11;
        end
        function v = XVelocity() % instantaneous velocity
            v = 12;
        end
        function v = XAcceleration()    % instantaneous acceleration
            v = 13;
        end
        function v = AngularVelocity() 
            v = 14;
        end
        function v = YVelocity() % instantaneous velocity
            v = 15;
        end
        function v = YAcceleration()
            v = 16;
        end
        function v = NUM_COLS() 
            v = 16;
        end

        % Additional columns - not always used
        function v = ImpliedEPTimeBased() % based on dx/dt
            v = 17;
        end
        function v = DxDt()
            v = 18;
        end
        function v = SmImpliedEp()
            v = 19;
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
                    nameByColNum{v} = method.Name;
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
