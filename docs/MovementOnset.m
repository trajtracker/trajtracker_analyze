%% TrajTracker analysis toolbox: Detecting the horizontal movement onset
% 
% Typically, we run finger-tracking experiments in order to look into how
% cognitive process evolves during the course of a trial. Finger
% trajectories provide a window to pre-response effects. 
% 
% One family of analyses is specifically interested in the earliest effects
% observable in finger movement. Among these early-effect analyses, an
% especially interesting one is the detection of *horizontal movement onset
% time*: computing, per trial, the earliest time point in which a
% significant sideways movement can be detected. This time point can be taken as
% an index of the processing time of the stimulus (or at least, its initial
% processing).
% 

%% The horizontal-movement-onset-time detection algorithm
% 
% The algorithm is described in detail, including results, in:
% 
% Dotan, D., & Dehaene, S. (2016). On the origins of logarithmic
% number-to-position mapping. _Psychological Review_, 123(6), 637-666,
% section 2.2.4.1.
% 
% *The basic idea is as follows.*
% The algorithm aims to identify the time point where the finger horizontal velocity starts building up. 
% A typical horizontal velocity profile of a trial consists of one or more velocity peaks 
% (which may reflect several successive movement plans), but as every experimental measure 
% it is also affected by jitter and random movements. 
% Our goal is to find the onset of the earliest non-random velocity peak. 
% To identify non-random peaks, we first estimate the participant's individual 
% level of "motor noise" based on the distribution of horizontal velocities during 
% an early time window (0-250 ms, assuming that before 250 ms the movement is not 
% yet affected by the target number). We consider only velocity peaks that are 
% significantly higher than this motor noise, and we find the onset of the earliest 
% of these peaks - as long as the onset occurred after 250 ms.
% 
% Going now into details: the horizontal velocity along each trajectory is
% already calculated when the data is preprocessed (_tt.preprocessSet()_).
% The velocities are stored, per trial, on
% 
%    trial.Trajectory(:, TrajCols.XVelocity)
% 
% To determine the horizontal movement onset per trial, we look for a significant 
% peak of the x velocity profile - the highest x velocity that exceeded the 
% top 1 percentile of the participant's velocity distribution on the first 
% 250 ms of all trials. The onset time of this peak x velocity is defined 
% as the latest time point where the x velocity remain lower than 5% of the 
% peak velocity (if velocity never gets below this threshold from 250 ms onwards,
% no onset is found for that trial and the peak is ignored). 
% To detect cases in which there is evidence for several successive movements 
% (several velocity peaks), we check if there is, earlier to the detected 
% movement onset, another significant velocity peak, and reapply the algorithm 
% to detect this peak's onset. 
% This procedure is applied recursively until no further velocity peak is detected.
% 
% The algorithm fails to find the movement onset when the peak velocity is 
% too low to reach significance, or when the above 5% criterion is never met 
% in the time window from 250 ms post onset until 100 ms before the 
% finger reaches the target (number line / response buttons). In such
% cases, you can review the trials for which the algorithm failed, and
% manually mark the movement onset time for each trial.
% 

%% Limits of this algorithm
% 
% The algorithm always fails to detect the onset of some trials. In the
% number-to-position paradigm, we recommend that you don't even try
% detecting the onset for targets close to the middle of the screen: in
% such trials, the movement is relatively straight so detecting sideways
% movement is hard and unreliable. In our data we excluded such mid-screen 
% trials, and the detection rate was around 85%-90%. 


%% Running the automatic detection algorithm
% 
% Within the TrajTracker toolbox, the onset detection algorithm is
% implemeted by the _tt.vel.findVelocityOnset()_ function.
% 
% This function calculates the velocity per trial, as described above. The
% result is several entries stored on each trial's _trial.Custom_. To see
% more details, run
% 
%    help tt.vel.findVelocityOnset
% 

%% Manual encoding of movement onsets
% 
% For trials in which the algorithm failed detecting the onset, you can try
% specifying the onset time manually. To do this, you can use the 
% _tt.vel.encodeVelocityOnsetManually()_ function. We designed this
% function to allow for onset encoding as fast as possible (if your data is
% good, you may succeed encoding 20+ trials per minute).
% The function shows you the velocity-by-time profile of each trial (using
% _tt.vel.plotVelocityProfile()_), one at a time, and lets you
% indicate the velocity onset time by clicking on the appropriate point on
% the graph. You use the keyboard to accept your onset selection and move to
% the next trial (or to skip a trial).
% 
% _encodeVelocityOnsetManually()_ saves your decisions to a CSV file. You
% then use _tt.vel.translateManualEncodingToMatlab()_ to translate this CSV file 
% into matlab code that udpates the manually-detected velocities (the generated
% matlab code will call _tt.vel.setTrialVelocityOnsetTime()_ for each trial). 
% 
% The idea is that you can paste the generated lines of matlab code into a 
% script that you create. This script would first call 
% _tt.vel.findVelocityOnset()_ to run the automatic detection, and then use the
% generated code to update the onset times for manually-encoded trials. For
% example, your script may look like this:
% 
%     %-- Automatic detection of horizontal movement onset time
%     tt.vel.findVelocityOnset(mydataset.d, 'MinTime', .25, 'MaxTime', -.1);
%   
%     %-- Manually-encoded movement onsets
%     tt.vel.setOnsetVelocityTime(mydataset.d, 'am', 21, 0.43, [], 0, 0, 0);
%     tt.vel.setOnsetVelocityTime(mydataset.d, 'am', 34, 0.402, [], 0, 0, 0);
%     tt.vel.setOnsetVelocityTime(mydataset.d, 'js', 5, 0.457, [], 0, 0, 0);
%     tt.vel.setOnsetVelocityTime(mydataset.d, 'js', 11, 0.228, [], 0, 0, 0);
%     tt.vel.setOnsetVelocityTime(mydataset.d, 'pq', 7, 0.422, [], 0, 0, 0);
%     tt.vel.setOnsetVelocityTime(mydataset.d, 'pq', 154, 0.382, [], 0, 0, 0);
%     tt.vel.setOnsetVelocityTime(mydataset.d, 'pq', 155, 0.241, [], 0, 0, 0);
% 
% This script will be run every time after you load your dataset into matlab.
