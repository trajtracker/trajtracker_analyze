function colors = targetColorScale(maxTarget)
% colors = targetColorScale(maxTarget) -
% Create color scale for showing target numbers

    nFivers = maxTarget/5 + 1;
    if (nFivers > 9)
        tmp = varycolor(nFivers);
        fiverColors = cell(nFivers,1);
        for i = 1:nFivers
            fiverColors{i} = tmp(i,:);
        end
    else
        fiverColors = {'red', [1 .3 .3], 'blue', [.3 .5 1], 'green', mycolors.darkgreen, 'black', [.4 .4 .4], mycolors.purple};
    end

    colors = cell(1,maxTarget+1);
    for i = 0:maxTarget
        fiver = floor(i/5);
        colors{i+1} = fiverColors{fiver+1};
    end

end
