% -----------------------------------------
% -- TrajTracker: package tt.preprocess  --
% -----------------------------------------
% Data pre-processing functions
% 
% <a href="matlab:help tt.preprocessSet">tt.preprocessSet</a>
% pre-process a dataset (directory) with experiment files (the help of this
% function also explains the expected directory structure).
% 
% <a href="matlab:help tt.preprocess.loadSessionAsExpData">tt.preprocess.loadSessionAsExpData</a>: 
% Load data of a single subject as a new ExperimentData object, including
% all necessary pre-processing. This is the function used by <a href="matlab:help tt.preprocessSet">tt.preprocessSet</a>
% 
% <a href="matlab:help tt.preprocess.createAverageTrials">tt.preprocess.createAverageTrials</a>
% Create a set of average trials for one ExperimentData
% 
% <a href="matlab:help tt.preprocess.getXmlAttr">tt.preprocess.getXmlAttr</a>: 
% Get an attribute from an XML object (obtained using <a href="matlab:help xml2struct">xml2struct</a>)
% 
% <a href="matlab:help tt.preprocess.loadSessionFile">tt.preprocess.loadSessionFile</a>:
% Load one session file - only the XML file (metadata), without
% trial/trajectory information.
% 
% <a href="matlab:help tt.preprocess.parsePath">tt.preprocess.parsePath</a>: 
% Parse a full file path into file name (basename) and the name of a
% sub-directory under <a href="matlab:help TrajTrackerDataPath">TrajTrackerDataPath</a>
% 
% 
% <a href="matlab:help tt.preprocess.updateDeviationFromDiagonal">tt.preprocess.updateDeviationFromDiagonal</a>: 
% Update the trajectory's amount of deviation from the diagonal line that
% goes from the START point straight to the screen corner.
% 
% <a href="matlab:help tt.preprocess.updateOutlierTrajectories">tt.preprocess.updateOutlierTrajectories</a>: 
% Per trial, find the area between its trajectory and the average trajectory of
% trials with the same target. Find trials where this area is an outlier.
% 
