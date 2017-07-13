%% TrajTracker analysis toolbox: Data formats
%
% 
%% Getting the raw results (from the experiment software) into matlab
% 
% After you ran an experiment, the results are downloaded as a set of 3
% file per experiment session (session = one block of one subject):
% 
% # Session file - with general info about the session
% # Trials file - a CSV file with one line per trial (including failed trials)
% # Trajectory file - a CSV file with one line per sampled finger positions
% Click <FileFormats.html here> for more details about the format of these files.
% 
% You then need to organize the files into *datasets*. 
%
% A dataset is the results of one or more subjects and it represents a
% basic analysis unit - i.e., this toolbox provides you with tools to
% analyze whole datasets.
%
% In a simple experiment, the dataset will be all data of all subjects. In
% an experiment with two conditions, you may have two datasets. And so on.
% 
% All data files of a dataset should be placed in a single directory:
%
% _[base]/[subdir]/raw_
% 
% Where [base] is the base path of all datasets (defined in the TrajTrackerDataPath
% function), and [subdir] is any path under [base].
% 
% You should also create a [base]/[subdir]/binary directory. This is where
% the toolbox will store files in matlab format (*.MAT)

%% Getting the data
% 
% To convert the data from raw format to the toolbox format, run the function
% _tt.preprocessSet(subdir)_
% 
% This will preprocess the dataset and save it in matlab format:
% [base]/[subdir]/binary/session_data.mat
% 
% To load the data as a matlab object, call _tt.loadDataset(subdir)_
% 
% In some cases you cannot break the raw data files into datasets - e.g.,
% if you have two conditions with mixed design. Don't worry about this:
% save them as one dataset, prepreocess and load them as such, and then you
% can break them into multiple datasets.
% 

%% How the data is stored as matlab objects
%
% The TrajTracker toolbox organizes the experiment data in three levels:
% 
% 1. *Dataset*: as explained above, this represents data of one dataset from one or more
%    subjects. The way you break the data into datasets is your own decision, 
%    the TrajTracker toolbox doesn't care about this.
% 
% 2. *Subject data*: the data of one subject in one dataset. This is stored as
%    one object (see details below).
%    In the documentation, we usually refer to this object as "expData".
% 
% .3 *Single trial*: each expData object contains a list of the trials.
%    Each trial is itself an object. The object includes general properties
%    of the trial (target, movement time, etc.) and details about the
%    trajectory.
%    
% If you loaded a dataset using _tt.loadDataset()_, you will get a struct with
% two entries: "raw" and "d". Each of them is again a struct, with one
% entry per subject (containing that subject's information).
% "raw" and "d" are two copies of the same dataset, with one difference:
% "raw" contains all trials per subject, whereas "d" contains just the
% non-failed trials (i.e., it excludes trials that had non-"OK" status
% in the trials.csv file).
% Both "raw" and "d" also contains a dummy subject called "all", which
% contains data of all subjects. "raw" also has a dummy subject called
% "avg", which contains average trajectories over all subjects.
% 

%%   ExperimentData and OneTrialData object - details
% 
% Experiment and trial data are objects defined using matlab classes.
% If you are not familiar with matlab classes and objects, read
% <matlab.html#2 this>.
% 
% Data from number-line experiments is stored as _NLExperimentData_
% objects, data from discrete-choice experiments is stored as _DCExperimentData_
% objects. Both these classes derive from _ExperimentData_.
%
% Data of one trial is a _OneTrialData_ object.
% 
% OneTrialData object includes:
% 
% * trial.TrialNum - the trial number, as defined in trials.csv
% * trial.TrialInd - the index of this trial among this subjects's trials
%                    in this dataset, i.e., dataset.raw.SUBJ_ID.Trials(trial.TrialInd) 
%                    will get the trial itself.
% * (Trajectory matrices)
% * (abs/norm time)
% * trial.Custom - struct with custom data. A class definition in matlab allows
%          storing only predefined attributes on each objects. If you want
%          to add your own stuff, put it on this struct.
%          Technically, you can set "trial.Custom" to any value, even
%          something that is not a struct. Don't do that, or you'll start
%          getting errors. Just write "trial.Custom.XXX = something"
% 
% An _ExperimentData_ object contains:
% 
% * Info about the subject (expData.SubjectName, expData.SubjectInitials, etc.)
% * expData.Trials - list of trials 
% * expData.AvgTrialsAbs and expData.AvgTrialsNorm - average trials. The
%   difference between them is in the way the averaging was done: averaging
%   can be done by grouping data points from the same absolute time (expData.AvgTrialsAbs)
%   or normalized time (expData.AvgTrialsNorm)
% * expData.Custom - custom data, similarly to "trial.Custom" (see above)
