% -----------------------------------------
% --     TrajTracker: package tt.vel     --
% -----------------------------------------
% Functions for velocity analysis
% 
% All these functions operate per trial:
% <a href="matlab:help tt.vel.findAccelerationBursts">findAccelerationBursts</a>: Find trajectory sections with high acceleration.
% <a href="matlab:help tt.vel.findAccelerationPeaks">findAccelerationPeaks</a>: Find highest acceleration points in a trajectory.
% <a href="matlab:help tt.vel.findSpeedNearAccPeak">findSpeedNearAccPeak</a>: Find x speed around acceleration peaks.
% <a href="matlab:help tt.vel.findVelocityOnset">findVelocityOnset</a>: Detect the first time of significant horizontal movement.
% <a href="matlab:help tt.vel.encodeVelocityOnsetManually">encodeVelocityOnsetManually</a>: Manually handle failures of findVelocityOnset().
% <a href="matlab:help tt.vel.getTrialVelocity">getTrialVelocity</a>: Calculate velocity and acceleration of a trial.
% <a href="matlab:help tt.vel.plotVelocityProfile">plotVelocityProfile</a>: Plot velocity/acceleration as a function of time.
% 
% Functions less useful:
% <a href="matlab:help tt.vel.findPercentOfPeak">findPercentOfPeak</a>: Find the time when x velocity reached a certain % of its peak.
% <a href="matlab:help tt.vel.setTrialVelocityOnsetTime">setTrialVelocityOnsetTime</a>: For manually overriding onset time.
