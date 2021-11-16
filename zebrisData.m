classdef zebrisData < handle
    % Container for zebris data.
    
    properties
        FirstName % First name of measured person
        LastName % Last name of measured person
        Born % Date of birth
        Sex % 
        Code % 
        Measured % Time stamp of measurement
        Description % 
        StepData % Collection of step data
        Type % zebris capture type
        Program % Program that created the *.xml file
        ProgramVersion % Version of FDM software, which created the *.xml file
        Source % *.xml source file
        Path % path to *.xml source file
    end
    
    methods
        function this = zebrisData()
            % Constructor
            this.StepData = struct;
        end
        
        function obj = importData(obj,PathName,FileName)
            % zebris.zebrisData.importData - Import data from zebris *.xml file
            % (not RAW but only data already pre-processed through FDM software). This means
            % that the *.xml file already contains data structured into steps.
            % For the documentation of the zebris *.xml file format see the FDM user manual, which
            % is available from the zebris website.

            s.Source = FileName;
            s.Path = PathName;
            s = molapp.DataIO.xml2struct(fullfile(PathName,FileName)); % Read zebris *.xml file

            obj.FirstName = s.measurement.patient.first_name.Text;
            obj.LastName = s.measurement.patient.last_name.Text;
            obj.Born = s.measurement.patient.born.Text;
            obj.Sex = s.measurement.patient.sex.Text;
            obj.Code = s.measurement.patient.code.Text;
            obj.Type = s.measurement.type.Text;
            obj.Program = s.measurement.program.Text;
            obj.ProgramVersion = s.measurement.program_version.Text;
            obj.Measured = s.measurement.measured.Text;
            obj.Description = s.measurement.description.Text;

            n = 1;
            b = 1;

            %%%%%%%%%%%%% *.xml data structure %%%%%%%%%%%%%%
            % - event: step1
            %     - type: zebris measure type
            %     - id: event id
            %     - 
            %     - rollover: pressure data from step 1
            %       - data
            %           - quant: time sample 1
            %           - quant: time sample 2
            %           - quant: time sample 3
            %           - ...
            % - event: step2
            %     - rollover: pressure data from step 2
            %         - data
            %             - quant: time sample 1
            %             - quant: time sample 2
            %             - quant: time sample 3
            %             - ...
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

            % - Subjects
            %     - Person1
            %         - Sessions
            %             - Gehen
            %                 - Measurements
            %                     - Messung1
            %                         - Data: c3dData, zebrisData
            %                         - Trials
            %                             - LeftLeg
            %                                 - GaitCycle1
            %                                 - GaitCycle2
            %                                 - GaitCycle3
            %                                 - ...
            %                             - RightLeg
            %                                 - GaitCycle1
            %                                 - GaitCycle2
            %                                 - GaitCycle3
            %                                 - ...
            %                     - Messung2
            %                     - Messung3
            %             - Laufen
            %     - Person2
            %     - Person3

            events = s.measurement.movements.movement.clips.clip.data.event;
            for m = 1:length(events)
                % loop throug all events (steps)
                rollover = events{m}.rollover;
                rows = str2double(events{m}.max.cell_count.y.Text);
                cols = str2double(events{m}.max.cell_count.x.Text);
                stepdata = zeros(rows+1,cols+1,size(rollover.data.quant, 2));
                for n = 1:size(rollover.data.quant, 2) 
                    % loop through time frames (quants) of step
                    c = strsplit(rollover.data.quant{1,n}.cells.Text);
                    c = str2double(c); % changing the current quant format to double
                    c(isnan(c)) = []; % removing NotANumber elements (at the beggining and at the end)
                    % preallocating space for the big array (whole rollover).
                    % To improve!.Later create path to values in
                    % the xml(2 for loops) +1 in row + column for 0 indexing
                    quantdata = zeros(rows+1,cols+1);
                    [row, col] = size(quantdata);
                    % checking size of the  individual quant
                    ncols = str2double(rollover.data.quant{1,n}.cell_count.x.Text); 
                    nrows = str2double(rollover.data.quant{1,n}.cell_count.y.Text);
                    % checking where does the quant starts inside of the big array
                    begincol = str2double(rollover.data.quant{1,n}.cell_begin.x.Text);
                    beginrow = str2double(rollover.data.quant{1,n}.cell_begin.y.Text);
                    cstart = begincol + 1;
                    cend = begincol + ncols; %removed +1
                    rstart = row - beginrow - nrows + 1; % added +1
                    rend = row - beginrow;
                    quantdata(rstart:rend,cstart:cend) = reshape(c,(ncols),(nrows))'; % placing the individual quant in the big array
                    %quantdata(beginrow:(nrows+beginrow-1), begincol:(ncols+begincol-1)) = reshape(c,(ncols),(nrows))'
                    stepdata(:,:,b) = quantdata; % adding time dimension
                    % n = n+1; % to access the next quant
                    b = b+1; % next time layer
                end
                stepname = ['Step',num2str(m)];
                obj.StepData.(stepname) = zebris.StepData;
                obj.StepData.(stepname).Name = stepname;
                obj.StepData.(stepname).Code = obj.Code;
                obj.StepData.(stepname).Pressure = stepdata; % storing the first rollover information inside of the participant class
                obj.StepData.(stepname).Type = events{m}.type.Text;
                obj.StepData.(stepname).Begin = str2double(events{m}.begin.Text);
                obj.StepData.(stepname).End = str2double(events{m}.end.Text);
                obj.StepData.(stepname).Side = events{m}.side.Text;
                obj.StepData.(stepname).Heel = [str2double(events{m}.heel.x.Text),str2double(events{m}.heel.y.Text)];
                obj.StepData.(stepname).Toe = [str2double(events{m}.toe.x.Text),str2double(events{m}.toe.y.Text)];
            end
        end

        function export2nifti(obj)
            % zebris.zebrisData.export2nifti - Export pressure data to the NIfTI file format

            stepnames = fields(obj.StepData);
            for m = 1:length(stepnames)
                obj.StepData.(stepnames{m}).export2nifti;
            end
        end
    end
end
