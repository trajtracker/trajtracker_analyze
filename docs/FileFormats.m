%% TrajTracker analysis toolbox: File formats
%
% This page describes the raw data files - the output of the
% experiment software, which serve as the input to this toolbox.
% 
% Each experiment session (one block of one subject) results in 3 files:
% * XML file with general info about the session
% * CSV file with trials information (one line per trial)
% * CSV file with trajectory information (one line per sampled point)
% 
% The column names in the CSV files are case insensitive.
% 
% 
%%  session.xml file
% 
% This file must be named "session_xxxxx.xml" (where xxxxx can be anything)
% 
% The file format is hereby detailed:
% 
%  <data>
%     <source>
%       <software name="TrajTracker" version="0.0.1"/>
%       <paradigm name="NL" version="1.0"/>
%     </source>
%     <subject id="js">
%        <name>John Smith</name>
%     </subject>
%     <session start-time="YYYY-MM-DD HH:MM">
%        <exp_level_results>
%           <data name="a" value="10.0" type="number"/>
%           <data name="b" value="hello" type="str"/>
%        </exp_level_results>
%        <files>
%           <file type="trials" name="trials_js.csv"/>
%            <file type="trajectory" name="trajectory_js.csv"/>
%        </files>
%     </session>
%  </data>
% 
% *Explanations:*
% 
% In these explanations, the notation "x.y" refers to attribute "y" in block "x"
% 
% * source: This block informs about the software that created the data.
% * subj.id: This will be used as the subject's identification in the
%            toolbox (e.g., when storing multiple subjects in a struct,
%            this is the key). 
%            If you omit this attribute, the default is a concatenation of
%            the subject's names first letters.
% * source.paradigm: either "NL", for number-line experiments, or "DC",
%             for discrete-choice experiments. 
% * session.start-time: date and time when the block started.
% * exp_level_results: custom information about the experiment and its result. 
%             Each entry will be saved as a custom attribute on the ExperimentData 
%             object (e.g., &lt;data name="a".../> will be saved as 
%             expData.Custom.a). The data type can be "number" (which will
%             be converted to a number) or "string".
% * files: reference to the data files of this session. Two files
%          are expected, listed as type="trials" and type="trajectory".
%          You can choose any name you want, but they must be in the
%          same directory.
% 
% The *exp_level_results* block must contain the following numeric entries:
% 
% * _WindowWidth_ and _WindowHeight_: the screen size, in pixels
% * _TrajZeroCoordX_, _TrajZeroCoordY_: The screen coordinates that correspond
%                 with the logical (matlab) coordinates (0,0). This is the
%                 point right above the "start" rectangle.
% 
% In number-to-position experiments, the following entries must appear too:
% 
% * _NLDistanceFromTop_: The number line's distance (in pixels) from the 
%   top of the screen.
% * _NumberLineMaxValue_: The numeric value at the right end of the number line
% * _NLLength_: The number line length, in pixels
% 
% In discrete-choice experiments, the following entries must appear too:
% 
% * _ResponseButtonWidth_, _ResponseButtonHeight_: the buttons size (in pixels)
% * _ResponseButton1X_, _ResponseButton1Y_, and same for button#2: their
%   positions (in pixels).
% 
% To validate the format of your XML file, you can try loading it by calling
% _tt.preprocess.loadSessionFile(filename)_
% 

%% Trials file
% 
% This is a CSV file with per-trial information.
%
% In this file, as well as in the trajectory file, the time-within-trial
% information is specified relatively to the beginning of the trial. 
% This is not necessarily the time when the finger started moving, or the
% time when the target was presented.
% 
% Columns in the trials file (header line case insensitive):
% 
% * SubSession: Defines how an experiment block was broken into sub-sessions
% * TrialNum: Trial number. Should be ordered.
%         This will be saved on "trial.TrialNum".
% * Status: End status of the trial. "OK" if the trial suceeded; for other 
%         error codes, see tt.preprocess.statusToErrCode()
%         Error code is converted to an internal code (see TrialErrCodes)
%         and saved on "trial.ErrCode".
% * Filler: an optional column used to indicate filler trials. If it exists,
%         and its value is 1, the trial's error code will be set to "filler".
% * Target (numeric): The trial's target. In number-line experiment, this is
%         the target position on the line. In discrete decision
%         experiments, this is the response button number (starting from 0).
%         This will be saved on "trial.Target".
% * PresentedTarget (string): The target actually presented to the participant,
%         or any representation of it, according to your choice. This will
%         be saved on "trial.Custom.PresentedTarget".
%         Make sure that this field will not contain comma characters, as
%         this could disrupt the CSV parsing.
% * TimeInSession: Time elapsed from the beginning of the session until the
%         trial started.
%         This will be saved on "trial.TimeInSession".
% * TimeUntilFingerMoved: Time elapsed from beginning of trial until finger
%         started moving.
%         This will be saved on "trial.TimeUntilFingerMoved".
% * TimeUntilTarget: Time elapsed from beginning of trial until the target
%         stimulus was presented.
%         This will be saved on "trial.TimeUntilTargetShown".
% * MovementTime: Time elapsed from the beginning of trial until a response was 
%         made. According to the experiment type, trial.MovementTime is set
%         to any of the following:
%         - This column (MovementTime)
%         - MovementTime-TimeUntilTarget
%         - MovementTime-TimeUntilFingerMoved
% * UserResponse: In discrete-choice experiments, this is the response
%         button selected.
% * EndPoint: In number-line experiments, this is the endpoint (specified
%         using the number line's scale).
% 
% Additional columns can be loaded using the "CustomCols" argument of
% _tt.preprocessSet()_.
% 

%% Trajectory file
% 
% This CSV file has one line per sample - i.e., multiple lines per trial.
% 
% *Columns:*
% 
% * TrialNum: The trial number. Should correspond with this column in trials.csv
% * x, y: Two columns for the x,y coordinates. See below for details about the
%       coordinate system.
% * time: The time elapsed from beginning-of-trial until sampling the x,y coordinates 
% 

%% The coordinate systems
% 
% TrajTracker-Experiment saves trajectory data using the screen's coordinate
% system: (0,0) is the middle of the screen, and the number of pixels depends
% on the system settings. Positive x values are the right side of the
% screen, and positive y values are on top of the screen.
% 
% When preprocessing the data into matlab objects, the coordinate system is
% changed, such that:
% 
% * x=0 refers to mid-of-screen
% * y=0 refers to the movement's starting point (right above the "start" 
%   rectangle at the bottom of the screen).
% * In number-to-position experiments, y=1 is the location of the number line.
% * In discrete choice experiments, x=1 is the right end of the screen and
%   x=-1 is its left end.
% 
% To enable conversion between these logical coordinate systems and the
% screen pixels, we maintain the scaling factor between them on the
% experiment data (ExperimentData.PixelsPerUnit).
% 
% The coodinate system conversion relies on several entries that must appear
% the *exp_level_results* block in the session.xml file: 
% WindowWidth, WindowHeight, TrajZeroCoordX, TrajZeroCoordY.
% For number-to-position experiments, the conversion also requires 
% NLDistanceFromTop. See above for details about all these entries.
% 
