function parseSessionFile_ttrk(session)
% parseSessionFile_ttrk(session) - Parse a session metadata file (XML),
% without the trial data, for new file format (TrajTracker app)

    parse_source_block(session)
    parse_subject_block(session)
    parse_session_block(session)

    %--------------------------------------------------------------
    function parse_source_block(session)
        
        source = session.xmlData.source;
        
        session.Software = source.software.Attributes.name;
        session.BuildNumber = source.software.Attributes.version;
        
        session.Platform = source.paradigm.Attributes.name;
        session.PlatformVersion = source.paradigm.Attributes.version;
        
    end

    %--------------------------------------------------------------
    function parse_subject_block(session)
        
        subjBlock = session.xmlData.subject;
        session.SubjID = subjBlock.Attributes.id;
        session.SubjInitials = subjBlock.Attributes.id;
        session.SubjName = subjBlock.name.Text;
        
    end

    %--------------------------------------------------------------
    function parse_session_block(session)

        sessionBlock = session.xmlData.session;
        
        session.StartTime = datetime(sessionBlock.Attributes.start_time);
        
        %-- Experiment-level results
        if isfield(sessionBlock.exp_level_results, 'data')
            data = sessionBlock.exp_level_results.data;
            if ~iscell(data), data = {data}; end
            for i = 1:length(data)
                value = data{i}.Attributes.value;
                switch(lower(data{i}.Attributes.type))
                    case 'number'
                        value = str2double(value);
                    case 'str'
                        % leave as it is
                    otherwise
                        error('Unsupported type (%s) in exp_level_results in file %s', data{i}.Attributes.type, session.Filename)
                end
                
                session.CustomAttrs.(data{i}.Attributes.name) = value;
            end
        end
        
        if ~isfield(session.CustomAttrs, 'MaxTarget')
            error('A "MaxTarget" field did not appear in exp_level_results in %s', session.Filename);
        end
        session.MaxTarget = session.CustomAttrs.MaxTarget;
        
        %-- Files
        if isfield(sessionBlock.files, 'file')
            files = sessionBlock.files.file;
            if ~iscell(files), files = {files}; end
            for i = 1:length(files)
                session.Files.(files{i}.Attributes.type) = files{i}.Attributes.name;
            end
        end
        
    end

end

