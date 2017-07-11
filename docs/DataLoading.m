%% TrajTracker analysis toolbox: Preparing and loading your data
%
% To prepare your data:
% 
% # Create a directory for your dataset (<DirStruct.html details...>).
% # Make sure you have the proper data files (<FileFormats.html details...>).
%   You should have a set of 3 files per subject per experiment session (block).
%   Store them in the "raw" sub-directory of your dataset.
% # Prepare your data by calling _tt.preprocessSet(ds_dir)_, where ds_dir is
%   your dataset's directory relatively to _TrajTrackerBasePath_.
%   This will save your data to *[base]/[ds_dir]/raw/session_data.mat*
% # If your dataset consists of several conditions and you wish to split
%   it into several datasets (so it's easier to analyze each separately),
%   create a directory for each of the new datasets, and write your own
%   function that creates a [base]/[ds_dir]/raw/session_data.mat file
%   in each of these directories.
% # Load the data to matlab by calling _tt.loadDataset(ds_dir)_.
% 
