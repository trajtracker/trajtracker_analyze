classdef GDExperimentData < ExperimentData
% Data of a decision experiment with several response alternatives
    
    methods
        
        function self = GDExperimentData(subjID, subjName, sessionID)
            self = self@ExperimentData('DC', subjID, subjName, sessionID);
        end
        
        function targets = getAllTargets(self)
            allTrg = arrayfun(@(t)t.Target, self.Trials);
            targets = unique(allTrg);
        end
        
        %---------------------------------------------------------------
        % Scaling factor of logical coordinates to screen coordinates
        % (make sure we get maximal X values of +/- 1)
        function v = logicalScaleToPixelsFactor(self)
            v = self.windowWidth() / 2;
        end
        
        %---------------------------------------------------------
        % Y coordinate of origin point
        % Counted from bottom of screen
        function v = originCoordY(self)
            if isfield(self.Custom, 'TrajZeroCoordY')
                y = self.Custom.TrajZeroCoordY;
            else
                y = 718;
            end
            v = self.windowHeight() - y;
        end
        
        %---------------------------------------------------------
        function v = windowHeight(self)
            if isfield(self.Custom, 'WindowHeight')
                v = self.Custom.WindowHeight;
            else
                v = 768;
            end
        end
        
        %---------------------------------------------------------
        function v = maxYPixels(self)
            v = self.windowHeight() - self.originCoordY();
        end
        
        %---------------------------------------------------------
        function v = maxYLogicalCoord(self)
            v = self.maxYPixels() / self.logicalScaleToPixelsFactor();
        end
        
        %---------------------------------------------------------
        function v = windowWidth(self)
            if isfield(self.Custom, 'WindowWidth')
                v = self.Custom.WindowWidth;
            else
                v = 1024;
            end
        end
        
    end
    
    
    
    methods(Access=protected)
        
        function copyOfSelf = createEmptyClone(self)
            copyOfSelf = GDExperimentData(self.SubjectID, self.SubjectName, self.SessionID);
        end
        
    end
    
    
end
