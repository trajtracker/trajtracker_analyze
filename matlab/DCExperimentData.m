classdef DCExperimentData < ExperimentData
% Data of a discrete-choice experiment with several response alternatives
    
    methods
        
        function self = DCExperimentData(initials, subjName)
            self = self@ExperimentData(initials, subjName);
        end
        
        function targets = getAllTargets(self)
            allTrg = arrayfun(@(t)t.Target, self.Trials);
            targets = unique(allTrg);
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
            copyOfSelf = DCExperimentData(self.SubjectInitials, self.SubjectName);
        end
        
        function p = getPlatform(~)
            p = 'DC';
        end
        
    end
    
    
end
