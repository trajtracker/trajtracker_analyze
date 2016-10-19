function args = stripArgs(args)

    while ~isempty(args) && iscell(args{1})
        
        if (length(args) == 1)
            args = args{1};
        else
            args = [args{1} args(2:end)];
        end
        
    end
    
end
