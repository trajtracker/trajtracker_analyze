function setTickDelta(axis, tickDelta, varargin)
%setTickDelta(axis, delta, ..) - set the X/Y ticks of a graph 
% to be with a certain spacing between them.
% The ticks will fill the graph range (according to xlim/ylim).
% 
% Arguments:
% Axis <axis> - 'x' or 'y'
% delta <number> - the distance between ticks
% 
% Optional arguments:
% Skip <N> - skip N labels between ticks (N=0 is no skips)
% Tick1Num <#> - when skipping, this is the number of the first tick to use
%                (default = 1)
% Precision <N> - specify precision for labels (N = number of positions after
%            the decimal dot).
%            (by default, find an appropriate precision).
% Lim [min max] - Put tick marks only between these limits
% 
% Written by Dror Dotan, 2016

    [tick1Num, tickSkip, precision, axisLim] = parseArgs(varargin);
    
    if isempty(axisLim)
        if strcmpi(axis, 'x')
            axisLim = xlim;
        elseif strcmpi(axis, 'y')
            axisLim = ylim;
        else
            error('Unsupported axis "%s"', axis);
        end
    end
    
    startTicks = ceil(axisLim(1) / tickDelta) * tickDelta;
    ticks = startTicks : tickDelta : axisLim(2);

    % -- Find default precision
    if isempty(precision)
        precision = findPrecision(ticks);
    end
    
    labels = arrayfun(@(y){formatRealNumber(y, 'Precision', precision)}, ticks);
    
    labels(mod(0:length(labels)-1, tickSkip+1) ~= (tick1Num-1)) = {''};
    
    set(gca, [axis 'Tick'], ticks);
    set(gca, [axis 'TickLabel'], labels);

    
    %-------------------------------------------------------
    function [tick1Num, tickSkip, precision, axisLim] = parseArgs(args)
        
        tick1Num = 1;
        tickSkip = 0;
        precision = [];
        axisLim = [];
        
        args = stripArgs(args);
        while ~isempty(args)
            switch(lower(args{1}))
                case 'skip'
                    tickSkip = args{2};
                    args = args(2:end);
                    
                case 'tick1num'
                    tick1Num = args{2};
                    args = args(2:end);
                    
                case 'precision'
                    precision = args{2};
                    args = args(2:end);
                    
                case 'lim'
                    axisLim = args{2};
                    args = args(2:end);
                    
                otherwise
                    error('Unsupported argument "%s"', args{1});
            end
            args = stripArgs(args(2:end));
        end
        
    end

end

