%===============================================================
%
%  TrialErrCodes - Possible error codes of a trial
%
%===============================================================
classdef TrialErrCodes
    
    methods(Static)
        function v = OK()
            v = 0;
        end
        
        function v = MultiFingers()
            v = 1;
        end
        function v = FingerLifted()
            v = 2;
        end
        function v = StartedSideways()
            v = 3;
        end
        function v = SpeechTooLate()
            v = 4;
        end
        function v = SpeechTooEarly()
            v = 5;
        end
        function v = Filler()
            v = 6;
        end
        function v = NoResponse() % For decision experiments
            v = 6;
        end
        function v = MovedBackwards()
            v = 10;
        end
        function v = TooSlowGlobal()
            v = 11;
        end
        function v = TooSlowInstantaneous()
            v = 12;
        end
        function v = FingerMovedTooEarly()
            v = 13;
        end
        function v = FingerMovedTooLate()
            v = 14;
        end
        function v = TooFast()
            v = 15;
        end
        
        % Error code set manually (after running the experiment) due to errors
        function v = Manual()
            v = 99;
        end
        
        
        % Naming errors
        function v = WrongNaming()
            v = 30;
        end
        function v = SpeechNotDetected()
            v = 31;
        end
        function v = NamingHesitation()
            v = 32;
        end
        
        function v = Outlier()
            v = 101;
        end
        
        function v = BackMovement()
            v = 102;
        end
        
        function v = TrialTooShort()
            v = 103;
        end
        
        %--------------------------------------------------------
        
        function [nameByCode, codeByName ,codes] = getAllErrCodes()
            nameByCode = struct;
            codeByName = struct;
            codes = [];
            methods = meta.class.fromName('TrialErrCodes').MethodList;
            for i = 1:length(methods)
                method = methods(i);
                if (method.Static && isempty(method.InputNames) && length(method.OutputNames) == 1 && strcmp(method.OutputNames{1}, 'v'))
                    v = eval(strcat('TrialErrCodes.', method.Name));
                    nameByCode.(sprintf('e%d', v)) = method.Name;
                    codeByName.(method.Name) = v;
                    codes = [codes v]; %#ok<AGROW>
                end
            end
        end
        
        function v = isValidRawErrCode(errCode)
            errCodes = [TrialErrCodes.OK:TrialErrCodes.Filler ...
                        TrialErrCodes.MovedBackwards:TrialErrCodes.TooSlowInstantaneous];
            v = sum(errCodes == errCode);
        end
        
        function v = isError(errCode)
            v = errCode ~= TrialErrCodes.OK & errCode ~= TrialErrCodes.Outlier;
        end
        
        function v = isStructuralSpeechError(errCode)
            v = ismember(errCode, [TrialErrCodes.SpeechNotDetected, TrialErrCodes.SpeechTooEarly, TrialErrCodes.SpeechTooLate]);
        end
        
        function v = isSpeechContentsError(errCode)
            v = ismember(errCode, [TrialErrCodes.WrongNaming, TrialErrCodes.NamingHesitation]);
        end
        
        function v = isAnySpeechError(errCode)
            v = TrialErrCodes.isStructuralSpeechError(errCode) | TrialErrCodes.isSpeechContentsError(errCode);
        end
        
    end
end
