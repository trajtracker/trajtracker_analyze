% -----------------------------------------
% -- TrajTracker: package tt.preprocess  --
% -----------------------------------------
% Data pre-processing functions
% 
% <a href="matlab:help tt.preprocessSet">tt.preprocessSet</a>: prepare a dataset to be used by this toolbox.
% <a href="matlab:help tt.preprocess.exportDataset">tt.preprocess.exportDataset</a>: Export a dataset back to to its raw input format (more or less).
% <a href="matlab:help tt.preprocess.createAverageTrials">tt.preprocess.createAverageTrials</a>: Average groups of trials (within ExperimentData) and save them
% <a href="matlab:help tt.preprocess.parsePath">tt.preprocess.parsePath</a>: Parse a path into file name + directory under <a href="matlab:help TrajTrackerDataPath">TrajTrackerDataPath</a>
% 
% <a href="matlab:help tt.preprocess.updateDeviationFromDiagonal">tt.preprocess.updateDeviationFromDiagonal</a>: Calculate the trajectory's deviation from "ideal" pointing
% <a href="matlab:help tt.preprocess.updateOutlierTrajectories">tt.preprocess.updateOutlierTrajectories</a>: Find trajectories with outlier deviations from average.
% 
% Functions that you probably don't need to use:
% <a href="matlab:help tt.preprocess.loadSessionAsExpData">tt.preprocess.loadSessionAsExpData</a>: Load one session data as a new ExperimentData object
% This function will also pre-process it.
% <a href="matlab:help tt.preprocess.loadSessionFile">tt.preprocess.loadSessionFile</a>: Load a session file (only session.xml, without trial/trajectory)
% <a href="matlab:help tt.preprocess.getXmlAttr">tt.preprocess.getXmlAttr</a>: Get attribute from a <a href="matlab:help xml2struct">xml2struct</a>-created XML object
