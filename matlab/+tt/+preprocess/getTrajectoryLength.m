function trajLen = getTrajectoryLength(x, y)

    trajLen = sum(sqrt(diff(x) .^ 2 + diff(y) .^ 2));

end
