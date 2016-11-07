function ec = statusToErrCode(errCodeStr)
%ec = statusToErrCode(errCodeStr) - convert a trial status (from
%trials.csv) to an error code

    switch(errCodeStr)
        case 'OK'
            ec = TrialErrCodes.OK;
        case 'ERR_MultiFingers'
            ec = TrialErrCodes.MultiFingers;
        case 'ERR_FingerLifted'
            ec = TrialErrCodes.FingerLifted;
        case 'ERR_StartedSideways'
            ec = TrialErrCodes.StartedSideways;
        case 'ERR_SpeechNotDetected'
            ec = TrialErrCodes.SpeechTooLate; % Changing to speech-too-late, which is usually the case. If indeed there was no speech, the error code will be later fixed manually
        case 'ERR_SpeechTooEarly'
            ec = TrialErrCodes.SpeechTooEarly;
        case 'ERR_MovedBackwards'
            ec = TrialErrCodes.MovedBackwards;
        case {'ERR_TooSlowGlobal', 'ERR_TooSlow'}
            ec = TrialErrCodes.TooSlowGlobal;
        case 'ERR_TooSlowInstantaneous'
            ec = TrialErrCodes.TooSlowInstantaneous;
        case 'ERR_MovedTooEarly'
            ec = TrialErrCodes.FingerMovedTooEarly;
        case 'ERR_MovedTooLate'
            ec = TrialErrCodes.FingerMovedTooLate;
        case {'ERR_TooFastMT', 'ERR_TooFastGlobal'}
            ec = TrialErrCodes.TooFast;
        case {'ERR_TrialTooShort', 'ERR_TooSlowMT'}
            ec = TrialErrCodes.TrialTooShort;
        case 'ERR_NoResponse'
            ec = TrialErrCodes.NoResponse;
        case 'ERR_Manual'
            ec = TrialErrCodes.Manual;
        otherwise
            error('Unknown error code "%s"', errCodeStr);
    end

end

