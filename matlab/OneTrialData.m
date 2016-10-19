classdef OneTrialData < handle
% The data of a single experiment trial
    
    properties
        TrialNum
        TrialIndex
        Target
        MovementTime
        TrajectoryLength
        ErrCode
        SubSession
        TimeInSubSession
        TimeUntilTargetShown
        TimeUntilFingerMoved
        
        Trajectory
        NormalizedTrajectory
        
        %-- the vector representing the trajectory initial direction
        InitialDirectionTheta
        InitialDirectionX0
        
        %-- Outlier analysis
        MaxDistanceFromAvgTraj
        AreaFromAverageTraj
        OutlierDueToArea     % True if the trajectory is an outlier because the area between it and the average trajectory (to the same target) is too large
        OutlierDueToDistance % True if the trajectory is an outlier because the peak distance between it and the average trajectory (to the same target) is too large
        
        PrevTarget % of previous trial
        
        Subject
        
        Custom % struct with custom properties
    end
    
    properties(Dependent=true)
        NTrajSamples         % No. of samples in the "Trajectory" data member
        X0                   % The X coordinate when crossing the origin line
        MeanVelocity         % average speed along the trajectory
        SamplingRate
        IsOutlierTrajectory
        dPrevTarget    % delta between current target and previous target
    end
    
    
    methods(Access=protected)
        
        function initFrom(self, c)
            self.TrialIndex = c.TrialIndex;
            self.Target = c.Target;
            self.Prime = c.Prime;
            self.MovementTime = c.MovementTime;
            self.TrajectoryLength = c.TrajectoryLength;
            self.ErrCode = c.ErrCode;
            self.SubSession = c.SubSession;
            self.TimeInSubSession = c.TimeInSubSession;
            self.TimeUntilTargetShown = c.TimeUntilTargetShown;
            self.TimeUntilFingerMoved = c.TimeUntilFingerMoved;
            self.Trajectory = c.Trajectory;
            self.NormalizedTrajectory = c.NormalizedTrajectory;
            self.InitialDirectionTheta = c.InitialDirectionTheta;
            self.InitialDirectionX0 = c.InitialDirectionX0;
            self.MaxDistanceFromAvgTraj = c.MaxDistanceFromAvgTraj;
            self.AreaFromAverageTraj = c.AreaFromAverageTraj;
            self.OutlierDueToArea = c.OutlierDueToArea;
            self.OutlierDueToDistance = c.OutlierDueToDistance;
            self.PrevTarget = c.PrevTarget;
            self.Subject = c.Subject;
            self.Custom = c.Custom;
        end
    end
    
    
    
    methods
        
        %==========================================
        % Constructor
        %==========================================
        function self = OneTrialData(trialNum, target)
            self.TrialNum = trialNum;
            self.Target = target;
            self.Custom = struct;
            self.OutlierDueToArea = false;
            self.OutlierDueToDistance = false;
        end
        
        
        %==========================================
        % Getters for some values
        %==========================================
        function value = get.NTrajSamples(self)
            value = size(self.Trajectory, 1);
        end
        
        function value = get.MeanVelocity(self)
            if (self.TrajectoryLength == 0)
                value = 0;
            else
                value = self.MovementTime / self.TrajectoryLength;
            end
        end
        
        function value = get.X0(self)
            value = self.Trajectory(1,TrajCols.X);
        end
        
        function value = get.SamplingRate(self)
            if (size(self.Trajectory,1) < 2)
                error('OneTrialData.SamplingRate cannot be retrieved before trajectory is set!');
            end
            t = self.Trajectory(1:2, TrajCols.AbsTime);
            value = t(2) - t(1);
        end
        
        function value = get.IsOutlierTrajectory(self)
            d1 = ~isempty(self.OutlierDueToDistance) && self.OutlierDueToDistance;
            d2 = ~isempty(self.OutlierDueToArea) && self.OutlierDueToArea;
            value = d1 || d2;
        end
        
        function value = get.dPrevTarget(self)
            value = self.Target - self.PrevTarget;
        end
        
        % Get a value from the trajectory matrix, while protecting against
        % index overflow
        function value = getTrajectoryValue(self,row,col)
            if row > 0
                row = min(row, size(self.Trajectory,1));
            else
                row = max(1, size(self.Trajectory,1)+row);
            end
            value = self.Trajectory(row, col);
        end
        
        
        %==========================================
        % Return specific trajectory elements
        %==========================================
        function v = times(self)
            v = self.Trajectory(:,TrajCols.AbsTime)';
        end
        function v = timePercentage(self)
            v = self.Trajectory(:,TrajCols.RelativeTime)';
        end
        function v = xValues(self)
            v = self.Trajectory(:,TrajCols.X)';
        end
        function v = yValues(self)
            v = self.Trajectory(:,TrajCols.Y)';
        end
        
        %==========================================
        % Get trajectory data in which there is a fixed number of points.
        % Interpolation is done by defining time slices.
        %==========================================
        function result = getTrajectoryWithFixedNumPoints(self, numPoints)
            if (numPoints < 2)
                error('Trajectories must have at least 2 points (%d is invalid)', numPoints);
            end
            
            normTime = self.Trajectory(:,TrajCols.RelativeTime);
            requiredTimePercentages = 0 : (1 / (numPoints-1)) : 1;
            times = spline(normTime, self.times, requiredTimePercentages);
            x = spline(normTime, self.xValues, requiredTimePercentages);
            y = spline(normTime, self.yValues, requiredTimePercentages);
            
            ep = self.Trajectory(:,TrajCols.ImpliedEP)';
            validIndices = logical(~isnan(ep));
            instImpliedEP = spline(normTime(validIndices), ep(validIndices), requiredTimePercentages);
            
            ang = self.Trajectory(:,TrajCols.AngularVelocity)';
            validIndices = logical(~isnan(ang));
            
            angularVelocity = spline(normTime(validIndices), ang(validIndices), requiredTimePercentages);
            
            result = [times; x; y; instImpliedEP; angularVelocity]';
        end
        
        %======================================================================
        %
        % Get trajectory data in which there is a fixed sampling rate.
        %
        % There is also a fixed number of points:
        % - If the number of points is too small, trajectory is chopped.
        % - If the number of points is too large, the last trajectory point
        %   is duplicated over and over again.
        %
        % Interpolation is done by defining time slices.
        %
        % trajColumns: the columns required in the result. The first column
        %              is always the absolute time, and then these columns
        %              will appear. If this variable is not specified, the
        %              default columns are: x,y,impliedEP
        %
        %======================================================================
        function result = getTrajectoryWithFixedSamplingRate(self, samplingRate, numPoints, trajColumns)
            if (numPoints < 2)
                error('Trajectories must have at least 2 points (%d is invalid)', numPoints);
            end
            if (samplingRate <= 0)
                error('Invalid sampling rate (%f)', samplingRate);
            end
            
            if (~ exist('trajColumns', 'var'))
                trajColumns = [TrajCols.X, TrajCols.Y, TrajCols.ImpliedEP];
            end
            
            requiredTimes = (0:samplingRate:samplingRate*(numPoints-1))';       % The required values of "AbsTime"
            availableTimes = requiredTimes(requiredTimes <= self.MovementTime); % The values available in the trial
            
            result = nan(length(requiredTimes), 1 + length(trajColumns));
            result(:,1) = requiredTimes;
            
            if (samplingRate == self.SamplingRate)
                % Take data from the trajectory
                nSamples = min(size(self.Trajectory, 1), numPoints);
                for i = 1:length(trajColumns)
                    result(1:nSamples,i+1) = self.Trajectory(1:nSamples, trajColumns(i));
                end
                lastRowNum = nSamples;
                
            else
                % Sampling rate is different from that specified in the
                % trial: interpolate until movement time
                for i = 1:length(trajColumns)
                    result(1:length(availableTimes),i+1) = spline(self.Trajectory(:,TrajCols.AbsTime), self.Trajectory(:,trajColumns(i)), availableTimes);
                end
                lastRowNum = length(availableTimes);
            end
            
            % If the required no. of points is longer than the trial, replicate the last time point as many times as required
            nMissingSamples = numPoints - lastRowNum;
            if (nMissingSamples > 0) 
                % lastRowNum = length(availableTimes);
                %lastLine = result(lastRowNum, :);
                result(lastRowNum+1:end,2:end) = repmat(result(lastRowNum, 2:end), nMissingSamples, 1);
                %lastTime = lastLine(1);
                %result(lastRowNum+1:lastRowNum+nMissingSamples, 1) = (lastTime+samplingRate):samplingRate:(lastTime+samplingRate*nMissingSamples);
            end

        end
        
        %==========================================
        % Return the trajectory in a fixed X resolution
        % i.e. X values will always range from 0 to 1, with 
        % increments of 0.0025 (= 401 trajectory points)
        %==========================================
        function xy = getFixedResolutionTrajectory(self)
            
            fixedResolutionXValues = 0:0.025:1;
            yValues = spline(self.xValues, self.yValues, fixedResolutionXValues);
            times = spline(self.xValues, self.times, fixedResolutionXValues);
            
            xy = [times; fixedResolutionXValues; yValues]';
        end
        
    end
    
    
end
