function setFigure(figID, doCLF)
%SETFIGURE(figID, doCLF) - Change to a specific figure and subplot
% 
% Arguments:
% figID - either a figure ID, or a 4-element array (figure ID + subplot info)
% doCLF - whether to clear ("clf") the selected figure

    if isempty(figID) && ~doCLF
        % Nothing to do
        return;
    end

    if ~isempty(figID)
        figure(figID(1));
    end
    
    if exist('doCLF', 'var') && doCLF
        clf;
    end
    
    if length(figID) >= 4
        subplot(figID(2), figID(3), figID(4));
    end

end

