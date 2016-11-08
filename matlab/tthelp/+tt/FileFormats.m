%             ------------------------------------------------
%             -- TrajTracker analysis toolbox: File formats --
%             ------------------------------------------------
%
% To show this again, run "help tt.FileFormats"
% 
% This help topic describes the raw data files - the output of the
% experiment software, which serve as the input to this toolbox.
% 
% Each experiment session (one block of one subject) results in 3 files:
% - XML file with general info about the session
% - CSV file with trials information (one line per trial)
% - CSV file with trajectory information (one line per sampled point)
% The column names in the CSV files are case insensitive.
% 
% 
%     session.xml file
% ++++++++++++++++++++++++
% 
% This file must be named "session_xxxxx.xml" (where xxxxx can be anything)
% 
% The file format is hereby detailed:
% 
% <data>
% <session>
%    <subject id="1234321" initials="js">
%       <name>John Smith</name>
%    </subject>
%    <experiment platform="NL"/>
%    <start-time>YYYY-MM-DD HH:MM</start-time>
%    <software-version>2.3.04d82<software-version>
%    <expLevelCounters>
%       <counter name="a" value="10.0"/>
%       <counter name="b" value="7.5"/>
%    </expLevelCounters>
%    <files>
%       <file type="trials" name="trials_1234321.csv"/>
%       <file type="trajectory" name="trajectory_1234321.csv"/>
%    </files>
% </session>
% </data>
% 
% Explanations:
% In these explanations, the notation "x.y" refers to attribute "y" in block "x"
% - subject.id: A unique ID of the subject.
% - subj.initials: This will be used as the subject's identification in the
%             toolbox (e.g., when storing multiple subjects in a struct,
%             this is the key). 
%             Initials is optional. If you omit this attribute, the default
%             is a concatenation of the subject's names first letters.
% - experiment.platform: either "NL", for number-line experiments, or "DC",
%             for discrete-decision experiments.
% - start-time: date and time when the block started.
% - software-version: XXXXXXXXXXXXXXXXXXXXXXXXXX
% - expLevelCounters: numeric counters. Each will be saved as a custom
%             attribute on the ExperimentData object (i.e., a counter named
%             "a" will be saved as expData.Custom.a)
% - files: reference to the data files of this session. Exactly two files
%             are expected, listed as type="trials" and type="trajectory".
%             You can choose any name you want, but they must be in the
%             same directory.
% 
% To validate the format of your XML file, you can try loading it by calling
% <a href="matlab:help tt.preprocess.loadSessionFile">tt.preprocess.loadSessionFile</a>(filename)
% 
% 
%     Trials file
% ++++++++++++++++++++++++
% This is a CSV file with per-trial information.
% In this file, as well as in the trajectory file, the time-within-trial
% information is specified relatively to the beginning of the trial. 
% This is not necessarily the time when the finger started moving, or the
% time when the target was presented.
% 
% Columns in the trials file:
% SubSession: allows breaking a session into sub-sessions
% TrialNum: Trial number. Should be ordered.
%         This will be saved on "trial.TrialNum".
% Status: End status of the trial. "OK" if the trial suceeded; for other 
%         error codes, see tt.preprocess.statusToErrCode()
%         Error code is converted to an internal code (see TrialErrCodes)
%         and saved on "trial.ErrCode".
% Filler: an optional column used to indicate filler trials. If it exists,
%         and its value is 1, the trial's error code will be set to "filler".
% Target (numeric): The trial's target. In number-line experiment, this is
%         the target position on the line. In discrete decision
%         experiments, this is the response button number (starting from 0).
%         This will be saved on "trial.Target".
% PresentedTarget (string): The target actually presented to the participant,
%         or any representation of it, according to your choice. This will
%         be saved on "trial.Custom.PresentedTarget".
% TimeInSession: Time elapsed from the beginning of the session until the
%         trial started.
%         This will be saved on "trial.TimeInSession".
% TimeUntilFingerMoved: Time elapsed from beginning of trial until finger
%         started moving.
%         This will be saved on "trial.TimeUntilFingerMoved".
% TimeUntilTarget: Time elapsed from beginning of trial until the target
%         stimulus was presented.
%         This will be saved on "trial.TimeUntilTargetShown".
% MovementTime: Time elapsed from the beginning of trial until a response was 
%         made. According to the experiment type, trial.MovementTime is set
%         to any of the following:
%         - This column (MovementTime)
%         - MovementTime-TimeUntilTarget
%         - MovementTime-TimeUntilFingerMoved
% TrajectoryLength: The length of the trajectory 
% UserResponse: In discrete-decision experiments, this is the response
%         button selected.
% EndPoint: In number-line experiments, this is the endpoint (specified
%         using the number line's scale).
% 
% Additional columns can be loaded using <a href="matlab:help tt.preprocessSet">tt.preprocessSet</a>'s "CustomCols" argument
% 
% 
%     Trajectory file
% ++++++++++++++++++++++++
% This CSV file has one line per sample - i.e., multiple lines per trial.
% 
% Columns:
% TrialNum: The trial number. Should correspond with this column in trials.csv
% x, y: Two columns for the x,y coordinates. See below for details about the
%       coordinate system.
% time: The time elapsed from beginning-of-trial until sampling the x,y coordinates 
% 
% 
%     The coordinate system
% +++++++++++++++++++++++++++++
% 
% After the data is preprocessed into matlab objects, we use a coordinate 
% system such that:
% - The valid range of y coordinates would be [0,1]
% - x=0 refers to mid-of-screen
% - y=0 refers to the virtual bottom of the screen (which is typically a
%   little above the "start" button).
% - We maintain the x-y ratio, i.e., they are both transformed with the same
%   stretch factor.
% 
% In the raw files, y=0 indicates the top of screen. The resolution is
% arbitrary - you can set it as you wish.
% To specify the raw files' coordinate system, add some counters in
% the <expLevelCounters> block in the session.xml file.
% - For number-line experiments: XXXXXXXXXXXXX TBD (for now it's fixed)
% - For discrete decision experiments:
%   Add a "WindowWidth" counter. The scaling factor will be set to half
%   the window width, such that x=1 is the right end of the screen and
%   x=-1 is its left end. To determine which raw y coordinate will become
%   y=0 in the prepreocessed data, add a "TrajZeroCoordY" counter. For
%   example, if your raw coordinate system is 1024x768, specifying
%   TrajZeroCoordY=718 sets y=0 tp be 50 pixels above the bottom of the
%   screen.
% 
%     More customization
% +++++++++++++++++++++++++++++
% The following entries can also be added under the <expLevelCounters> block 
% in the session.xml file:
% - NumberLineMaxValue: This is a mandatory entry for number-line
%           experiments. It sets the number's line top (rightmost) value.
% - iEPYCoord: An optional argument, relevant only for discrete-decision
%           experiments. This determines the y coordinate that should be
%           used for calculating implied endpoints. By default, we use the
%           top-of-screen y coordinate.
%           You can override this settings in <a href="matlab:help tt.preprocessSet">tt.preprocessSet()</a>
