%-------------------------------------------------------------------
%-- TrajTracker analysis toolbox: Preparing and loading your data --
%-------------------------------------------------------------------
%
% To prepare your data:
% 1. Create a directory for your dataset (see <a href="matlab:help tt.DirStruct">help tt.DirStruct</a>).
% 2. Make sure you have the proper data files (see <a href="matlab:help tt.FileFormats">help tt.FileFormats</a>).
%    You should have a set of 3 files per subject per experiment session (block).
%    Store them in the "raw" sub-directory of your dataset.
% 3. Prepare your data by calling <a href="matlab:help tt.preprocessSet">tt.preprocessSet</a>(ds_dir), where ds_dir is
%    your dataset's directory relatively to <a href="matlab:help TrajTrackerBasePath">TrajTrackerBasePath</a?.
%    This will save your data to base/ds_dir/raw/session_data.mat
% 4. If your dataset consists of several conditions and you wish to split
%    it into several datasets (so it's easier to analyze each separately),
%    create a directory for each of the new datasets, and write your own
%    function that creates a base/ds_dir/raw/session_data.mat file
%    in each of these directories.
% 5. Load the data to matlab by calling <a href="matlab:help tt.loadDataset">tt.loadDataset</a>(ds_dir).
% 

help tt.DataLoading
