function setFigWindowSize(winSize)
%setFigWindowSize([width height]) - 
% set the window size for the current figure (gcf)

    if isempty(winSize)
        return;
    end
    
    screenSize = get(0,'Screensize');
    x = (screenSize(3) - winSize(1)) / 2;
    y = (screenSize(4) - winSize(2)) / 2;
    set(gcf, 'Position', [x y winSize]);
    
end

