function nOutliers = updateOutlierTrajectories(expData)
% nOutliers = updateOutlierTrajectories(expData)
% Per trial, find the area between its trajectory and the average
% trajectory of trials having the same target.

    % This flag decides whether the outliers are considered globally (over
    % all targets) or locally (per target)
    USE_GLOBAL_OUTLIER = 0;
    
    initAllTrialsToNonOutlier(expData);
    
    cleanExpData = expData.filterTrialsWithErrCode(TrialErrCodes.OK);
    
    avgTrajPerTarget = createAvgTrajPerTarget(cleanExpData);
    
    areaPerTrial = calcAreaBetweenEachTrajectoryAndAvg(cleanExpData.Trials, avgTrajPerTarget);
    isOutlierByArea = checkIfOutlier(areaPerTrial, cleanExpData);
    
    distancePerTrial = calcMaxDistanceBetweenEachTrajectoryAndAvg(cleanExpData.Trials, avgTrajPerTarget);
    isOutlierByDistance = checkIfOutlier(distancePerTrial, cleanExpData);
    
    for i = 1:length(cleanExpData.Trials)
        cleanExpData.Trials(i).OutlierDueToArea = isOutlierByArea(i);
        cleanExpData.Trials(i).OutlierDueToDistance = isOutlierByDistance(i);
    end
    
    nOutliers = sum(isOutlierByArea | isOutlierByDistance);
    
    %---------------------------------------------------------------------
    function avgTrajectories = createAvgTrajPerTarget(expData)
        
        avgTrajectories = cell(length(expData.getAllTargets()), 1);
        
        normTrajLength = 201; %%%DDD size(expData.Trials(1).NormalizedTrajectory, 1);
        
        targets = arrayfun(@(t)t.Target, expData.Trials);
        
        for target = expData.getAllTargets()

            trialsOfTarget = logical(targets == target);
            if (sum(trialsOfTarget) == 0)
                % No trials with this target
                continue;
            end
            
            % Get the average trajectory for trials of this target
            avgTrajectory = tt.preprocess.averageTrajectoryByNormTime(expData.Trials(trialsOfTarget), normTrajLength, 'median');
            x = avgTrajectory(:,2);
            y = avgTrajectory(:,3);
            trajLength = tt.preprocess.getTrajectoryLength(x, y);
            
            avgTrajectories{target+1} = struct('x', x, 'y', y, 'length', trajLength);
        end
    end
    
    %---------------------------------------------------------------------
    function areas = calcAreaBetweenEachTrajectoryAndAvg(trials, avgTrajectories)
        areas = NaN(length(trials),1);
        
        for ii = 1:length(trials) 
            trial = trials(ii);
            if (trial.ErrCode ~= TrialErrCodes.OK)
                % Ignore erroneous trajectories (or - in some cases - there
                % would be no trajectory at all)
                continue;
            end
            
            relevantAvgTrjectory = avgTrajectories{trial.Target+1};
            
            area = calcAreaBetweenTrajectoryAndAvg(relevantAvgTrjectory.x, relevantAvgTrjectory.y, ...
                trial.Trajectory(:,TrajCols.X), trial.Trajectory(:,TrajCols.Y)); %%%DDD NormTraj previously used here
            
            areas(ii) = area / relevantAvgTrjectory.length;
            trial.AreaFromAverageTraj = areas(ii);
        end
        
    end
    
    %---------------------------------------------------------------------
    function distances = calcMaxDistanceBetweenEachTrajectoryAndAvg(trials, avgTrajectories)
        distances = NaN(length(trials),1);
        
        for ii = 1:length(trials) 
            trial = trials(ii);
            if (trial.ErrCode ~= TrialErrCodes.OK)
                % Ignore erroneous trajectories (or - in some cases - there
                % would be no trajectory at all)
                continue;
            end
            
            relevantAvgTrjectory = avgTrajectories{trial.Target+1};
            
            distances(ii) = max(arrayfun(@(ind)distanceToAvgTraj(trial.Trajectory(ind, TrajCols.X), ...
                                                                 trial.Trajectory(ind, TrajCols.Y), ...
                                                                 relevantAvgTrjectory.x, relevantAvgTrjectory.y), ...
                                                                 1:3:size(trial.Trajectory,1)));
            trial.MaxDistanceFromAvgTraj = distances(ii);
        end
        
    end

    %---------------------------------------------------------------------
    % Get a value per trial, and check whether it's an outlier
    function outlier = checkIfOutlier(valuePerTrial, expData)
        
        if (USE_GLOBAL_OUTLIER)
            
            outlier = isOutlier(valuePerTrial) > 0;
            
        else
            targets = arrayfun(@(t)t.Target, expData.Trials);
            outlier = zeros(length(expData.Trials), 1);

            for target = 0:expData.MaxTarget
                relevantInds = logical(targets == target);
                outlier(relevantInds) = isOutlier(valuePerTrial(relevantInds)) > 0;
            end
        end
        
    end
    
    
    %---------------------------------------------------------------------
    function initAllTrialsToNonOutlier(expData)
        for tr = expData.Trials
            tr.OutlierDueToArea = 0;
            tr.OutlierDueToDistance = 0;
        end
    end

    %---------------------------------------------------------------------
    % Calculate the area between the average trajectory and another
    % trajectory.
    function a = calcAreaBetweenTrajectoryAndAvg(avgX, avgY, x, y)
        
        dx = abs(spline(y, x, avgY) - avgX);
        
        y = [avgY(1); avgY; avgY(end)];
        dy = abs(y(3:end) - y(1:end-2)) / 2;
        
        a = sum(dx .* dy);
    end
    
    %---------------------------------------------------------------------
    % Calculate the distance from a point to the average trajectory curve
    function d = distanceToAvgTraj(x, y, avgX, avgY)
        d = min(sqrt((avgX - x) .^ 2 + (avgY - y) .^ 2));
    end

end
