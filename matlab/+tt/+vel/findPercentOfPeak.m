function findPercentOfPeak(allExpData, pcntOfPeak, varargin)
% findPercentOfPeak(allExpData, pcntOfPeak, ...) -
% Find the time in which the velocity reached a certain percentage of the
% first velocity peak


    [customAttrNames] = parseArgs(varargin);
    
    nl.basic.doPerTrial(allExpData, @processTrial);

    
    %----------------------------------------------------
    function processTrial(trial, ~)
        
        if isempty(trial.Custom.XVelocityPeakRows)
            return;
        end
        
        firstPeakRow = trial.Custom.XVelocityPeakRow(1);
        firstVelocityPeak = trial.Trajectory(firstPeakRow, TrajCols.XVelocity);
        firstVelocityPeakDirection = sign(firstVelocityPeak);
        
        velocities = trial.Trajectory(1:firstPeakRow-1, TrajCols.XVelocity) * firstVelocityPeakDirection;
        
        % Find the LAST row that does not yet cross the threshold
        lastSlowRow = find(velocities < firstVelocityPeak*pcntOfPeak, 'last');
        if isempty(lastSlowRow)
            lastSlowRow = 0;
        end
        
        trial.Custom.(customAttrNames.RowAttr) = lastSlowRow+1;
        trial.Custom.(customAttrNames.TimeAttr) = trial.Trajectory(lastSlowRow+1, TrajCols.AbsTime);
        
    end

    %----------------------------------------------------
    function [customAttrNames] = parseArgs(args)
        
        customAttrNames = struct('RowAttr', 'HighSpeedRow', 'TimeAttr', 'HighSpeedTime');
        
        args = stripArgs(args);
        while ~isempty(args)
            
            switch(lower(args{1}))
                case 'attrprefix'
                    pref = args{2};
                    args = args(2:end);
                    customAttrNames.RowAttr = strcat(pref, 'Row');
                    customAttrNames.TimeAttr = strcat(pref, 'Time');
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            
            args = stripArgs(args(2:end));
            
        end
    end

end
