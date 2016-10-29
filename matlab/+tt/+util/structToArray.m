function edArray = structToArray(edStruct, varargin)
% edArray = structToArray(edStruct[, subjIDs])
% Convert a struct with several ExpData's into an array

    if isempty(setdiff(fieldnames(edStruct), {'raw', 'd'}))
        error('Please provide "dataset.d" or "dataset.raw" as the argument');
    end
    
    [subjIDs] = parseArgs(varargin, edStruct);
    
    edArray = myarrayfun(@(id)edStruct.(id{1}), subjIDs);
    
    %-------------------------------------------
    function [subjIDs] = parseArgs(args, edStruct)

        subjIDs = tt.inf.listInitials(edStruct);
        getJustOneED = false;
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'subjIDs'
                    subjIDs = args{2};
                    args = args(2:end);

                case 'any'
                    getJustOneED = true;
                    
                otherwise
                    error('Unsupported argument "%s"!', args{1});
            end
            args = stripArgs(args(2:end));
        end

        if getJustOneED
            subjIDs = subjIDs(1);
        end
        
    end

end
