function result = createExpDataAll(expDataArray)
% Create an "all" experiment data obj, i.e., an ExperimentData object that
% contains all trials from several ExperimentData's

    if isempty(expDataArray)
        error('Empty input');
    end

    switch(expDataArray(1).ExperimentPlatform)
        case 'NL'
            result = NLExperimentData(expDataArray(1).MaxTarget, 'all', 'All Participants');
            if length(unique(arrayfun(@(ed)ed.MaxTarget, expDataArray))) > 1
                error('Experiments with inconsistent MaxTarget cannot be merged');
            end
            
        case 'DC'
            result = GDExperimentData('all', 'All Participants');
            
        otherwise
            error('Unsupported platform: %s', expDataArray(1).ExperimentPlatform);
    end
    
    for expData = expDataArray
        result.addAllTrialsOf(expData);
    end
    
end
