function array = mycell2array(cellArray)

    array = [];
    for elem = cellArray
        array = [array elem{1}];
    end
    
end
