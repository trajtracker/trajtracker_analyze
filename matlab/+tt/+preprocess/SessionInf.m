classdef SessionInf < handle
    %SESSIONINF Metadata information about an experiment session
    
    properties
        Filename
        SubDir
        SubjID
        SubjInitials
        SubjName
        Platform
        BuildNumber
        StartTime
        CustomAttrs
        Files
        xmlData
        
        %-- Relevant only for NL
        MaxTarget
    end

    properties(Dependent=true)
        RawFilePath
        RawDir
    end    
    
    
    methods
        
        function self = SessionInf(subDir, filename)
            self.SubDir = subDir;
            self.Filename = filename;
            self.CustomAttrs = struct;
            self.Files = struct;
        end
        
        function v = get.RawFilePath(self)
            v = [self.RawDir '/' self.Filename];
        end
        
        function v = get.RawDir(self)
            v = [TrajTrackerDataPath '/' self.SubDir '/raw'];
        end
        
        
        %----------------------------------------------------------
        function value = getXmlBlock(self, subEntityNames)

            value = self.xmlData;
            if ischar(subEntityNames), subEntityNames = {subEntityNames}; end;

            for i = 1:length(subEntityNames)
                e = subEntityNames{i};
                if ~isfield(value, e)
                    error('Entity "%s" was found in session', join('.', subEntityNames(1:i)));
                end
                value = value.(e);
            end

        end
        
    end
        
end

