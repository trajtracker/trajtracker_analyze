function session = loadSessionFile(filename)
% session = loadSessionFile(filename) - Load a session metadata file (XML),
% without the trial data.
% 
% Return a SessionInf object.

    [subDir, bn] = tt.preprocess.parsePath(filename);
    session = tt.preprocess.SessionInf(subDir, bn);
    
    xml = xml2struct(filename);
    session.xmlData = xml.data;
    
    xmlSession = getSubEntity(session.xmlData, 'session', 'data');
    
    xmlSubj = getSubEntity(xmlSession, 'subject', 'session');
    session.SubjID = tt.preprocess.getXmlAttr(xmlSubj, 'id', 'subject', filename);
    session.SubjName = getSubEntity(xmlSubj, {'name', 'Text'}, 'subject');
    if isfield(xmlSubj.Attributes, 'initials')
        session.SubjInitials = xmlSubj.Attributes.initials;
    else
        session.SubjInitials = getDefaultInitials(session.SubjName);
    end

    xmlExp = getSubEntity(xmlSession, 'experiment', 'session');
    session.Platform = tt.preprocess.getXmlAttr(xmlExp, 'platform', 'experiment', filename);
    
    startTime = getSubEntity(xmlSession, {'start_dash_time', 'Text'}, 'session');
    try
        session.StartTime = datetime(startTime);
    catch eee
        error('Invalid session file %s: unknown format for session.start-time (%s)', filename, startTime);
    end
    
    softwareVer = getSubEntity(xmlSession, {'software_dash_version', 'Text'}, 'session');
    [~, session.BuildNumber] = parseSoftwareVersion(softwareVer, filename);
        
    parseCustomAttrs(session);
    getAttachedFilenames(session);
    
    if strcmp(session.Platform, 'NL')
        if (session.BuildNumber <= 50)
            session.MaxTarget = str2double(getSubEntity(xmlSession, {'max_dash_target', 'Text'}, 'session'));
        else
            session.MaxTarget = session.CustomAttrs.NumberLineMaxValue;
        end
    end
    
    
    %----------------------------------------------------------
    function value = getSubEntity(xml, subEntityNames, entityName)
        
        value = xml;
        if ischar(subEntityNames), subEntityNames = {subEntityNames}; end;
        
        for i = 1:length(subEntityNames)
            e = subEntityNames{i};
            if ~isfield(value, e)
                error('Invalid session file (%s): no entity "%s" was found in block <%s>', filename, join('.', subEntityNames(1:i)), entityName);
            end
            value = value.(e);
        end
        
    end

    %--------------------------------------------------
    function initials = getDefaultInitials(subjName)
        
        names = regexp(subjName, ' ', 'split');
        names = names(arrayfun(@(n)~isempty(n{1}), names));
        initials = lower(arrayfun(@(n)n{1}(1), names));
        
    end
    
    %-------------------------------------------------------------------
    function [softwareVer, buildNum] = parseSoftwareVersion(rawVer, sessionInfoFilename)
        tokens = regexpi(char(rawVer), '^([0-9.]+)\.?d(\d+)$', 'tokens');
        if (isempty(tokens)) 
            error('Invalid software version (%s) in %s', char(rawVer), sessionInfoFilename);
        end
        tokens = tokens{1};
        softwareVer = char(tokens{1});
        buildNum = str2double(char(tokens{2}));
    end

    %-------------------------------------------------------------------
    function parseCustomAttrs(session)
        if (session.BuildNumber <= 50)
            return; % No custom attribute info
        end
        if ~isfield(session.xmlData.session, 'expLevelCounters')
            return;
        end

        counters = session.xmlData.session.expLevelCounters.counter;
        for i = 1:length(counters)
            counter = counters{i};
            session.CustomAttrs.(counter.Attributes.name) = str2double(counter.Attributes.value);
        end
    end

    %-------------------------------------------------------------------
    function getAttachedFilenames(session)
        if ~isfield(session.xmlData.session, 'files') || ~isfield(session.xmlData.session.files, 'file')
            error('Invalid session file (%s): no <files><file> entry was found in the session block. If this file comes from an old, iPad version of TrajTracker, you should run the pre-processing PERL script (preprocessSet.pl)', filename);
        end
        
        fileXml = session.xmlData.session.files.file;
        for i=1:length(fileXml)
            file = fileXml{i};
            session.Files.(file.Attributes.type) = basename(file.Attributes.name);
        end
    end

end

