classdef SpeWriter < hgsetget
    %SpeWriter Create a video writer object.
    %   
    %   OBJ = SpeWriter(FILENAME) constructs a spe-file Writer object to
    %   write video data to a SPE file that uses uncompressed grayscale images.  
    %   FILENAME is a string enclosed in single quotation marks that specifies 
    %   the name of the file to create. If filename does not include the 
    %   extension '.spe', the SpeWriter constructor appends the extension.
    %
    % Methods:
    %   open        - Open file for writing video data. 
    %   close       - Close file after writing video data.
    %   writeVideo  - Write video data to file.
    %
    % Properties:
    %   FileFormat             - String specifying the type of file to write.
    %   Filename               - String specifying the name of the file.
    %   Height                 - Height of each video frame in pixels. 
    %                            The writeVideo method sets values for Height
    %                            and Width based on the dimensions of the 
    %                            first frame.
    %   Path                   - String specifying the fully qualified file
    %                            path.
    %   FrameCount             - Number of frames written to the video file.
    %   Width                  - Width of each video frame in pixels. 
    %                            The writeVideo method sets values for Height
    %                            and Width based on the dimensions of the 
    %                            first frame.
    %
    % Example:
    % 
    %   % Prepare the new file.
    %   vidObj = SpeWriter('peaks.spe');
    %   open(vidObj);
    %
    %   % Create an animation.
    %   Z = peaks; surf(Z);
    %   axis tight
    %   set(gca,'nextplot','replacechildren');
    %
    %   for k = 1:20
    %      surf(sin(2*pi*k/20)*Z,Z)
    %
    %      % Write each frame to the file.
    %      currFrame = getframe;
    %      writeVideo(vidObj,currFrame);
    %   end
    % 
    %   % Close the file.
    %   close(vidObj);
    % 
    % See also VideoWriter
    
    %   Author: JaW
    %   Based upon VideoWriter implementation by NH DT - The Mathworks
    %   Class SpeWriter extends hgsetget superclass, in order to customly
    %   get/set some properties
    %   The class SpeReader is required to obtain some spe-specific info.
    
    properties(SetAccess=private)
        Name      %The name of the file to be written.
        FileFormat    %The format of the file to be written.
        Path          %The path to the file to be written.
    end
    
    properties(Access='public')
        Tag = '';       % Generic string for the user to set.
    end
    
    properties(GetAccess='public', SetAccess='private')
        Type            % Classname of the object.
    end
    
    properties (SetAccess=private, Transient)
        Height = []; % Height of the video being created
        Width = []; % Width of the video being created
        FrameCount = 0; % The total number of frames written to the file
    end
    
    properties(SetAccess=private, Hidden, Transient)
        IsOpen = false; %Indicates if the file is open for writing.
    end
    
    properties(Access=private)
        EnforcedDataType % Datatype which should be enforced (set after 1st frame)
        FileIdentifier %fileid after called by fopen
    end
    
    methods
        function obj = SpeWriter(filename)
            
            % If no file name provided.
            if nargin == 0
                error('FILENAME must be specified.');
            end
            
            if ~ischar(filename) || isempty(filename)
                error('FILENAME must be a string');
            end
            
            if ~exist('SpeReader','class')
                error('class SpeReader cannot be found in path or working directory!')
            end
            
            % Many MATLAB functions assume that any slashes in a file name
            % are really the filesep for the current platform.
            filename = regexprep(filename, '[\/\\]', filesep);
            
            [pathstr, baseFile, extProvided ] = fileparts(filename);
            
            % Validate that the directory specified exists.
            if isempty(pathstr)
                pathstr = pwd;
            end
            
            if ~exist(pathstr, 'dir')
                error(['Unable to locate directory: ' pathstr]);
            end
            
            
            % Validate that the filename has the correct extension.
            if ~strcmpi(extProvided, '.spe')
                extProvided = [extProvided '.spe'];
            end
            
            filename = fullfile(pathstr, [baseFile extProvided]);
            
            % Test that the file can actually be created.
            % Open it in append mode so that any existing file is not
            % destroyed.
            fileExisted = (exist(filename, 'file') ~= 0);
            fid = fopen(filename, 'a');
            
            if (fid ~= -1)
                % Since the file is write-able and currently exists, use
                % fileattrib to convert the filename into a fully qualified
                % absolute path.
                [~, info] = fileattrib(filename);
                if usejava('jvm')
                    jf = java.io.File(info.Name);
                    filename = char(jf.getCanonicalPath());
                else
                    filename = info.Name;
                end
                fclose(fid);
            end
            
            if (~fileExisted && (fid ~= -1))
                delete(filename);
            end
            
            if (fid == -1)
                error(['Permission error: unable to write to ' filename]);
            end
            
            % init file properties
            [pathstr file ext] = fileparts(filename);
            obj.Name = [file ext];
            obj.Path = pathstr;
            
        end
        
        function delete(obj)
            %DELETE Delete a SpeWriter object.
            %   DELETE does not need to called directly, as it is called when
            %   the SpeWriter object is cleared.  When DELETE is called, the
            %    object is closed and the file is no longer writable.
            close(obj)
        end
        
        function open(obj)
            %OPEN Open a VideoWriter object for writing.
            %   OPEN(OBJ) must be called before calling the writeVideo
            %   method, at the moment it really doesn't do much at all
            
            if length(obj) > 1
                error('inproper object supplied!');
            end
            
            if obj.IsOpen
                % If open is called multiple times, there should be no
                % effect.
                return;
            end
            
            fileName = obj.getFileName;
            fd = fopen(fileName,'w+','native','UTF-8');
            if(fd < 0)
                error('Could not open file, bad filename')
            end
            
            obj.FileIdentifier = fd;
            obj.IsOpen = true;
            
            try
                obj.writeHeader;
            catch exception
                error(['error while processing file-header: ' exception.message])
            end
        end
        
        function close(obj)
            % CLOSE Finish writing and close video file.
            %
            %   CLOSE(OBJ) closes the file associated with video
            %   writer object OBJ.
            
            for ii = 1:length(obj)
                if ~obj(ii).IsOpen
                    continue;
                end
                
                if obj(ii).FrameCount == 0
                    warning('spewriter:noframes','no frames written');
                end
                
                obj.writeFooter;
                fclose(obj.FileIdentifier);
                obj.FileIdentifier = [];
                obj(ii).IsOpen = false;
            end
        end
        
        function writeVideo(obj,frame)
            % writeVideo write video data to a file
            
            %check if input is 2 files, if not, return error of type struct
            error(nargchk(2,2, nargin, 'struct'))
            
            if length(obj) > 1 %check on proper object
                error('inproper object supplied!');
            end
            
            if ~obj.IsOpen %check if object is open, thus file is open
                error('file has not been opened yet!');
            end
            
            if (obj.FrameCount > 0) %check on height/width after first frame
                [frameHeight, frameWidth] = SpeWriter.getFrameSize(frame);
                %if framedimensions are not consistent, throw error:
                if ( (frameHeight ~= obj.Height) || (frameWidth ~= obj.Width) )
                    error(['invalidDimensions:' obj.Width '*' obj.Height]);
                end
            end
            try
                if isstruct(frame)
                    %if input is some typical movie structure, convert it
                    %to 4-D array
                    frame = frame2im(frame);
                    obj.writeFrames(frame);
                else
                    obj.writeFrames(frame);
                end
            catch err
                throw(err)
            end
        end
        
    end
    
    methods(Static, Access=private)
        function [height width] = getFrameSize(frame)
            % Determine the height and width of a frame independent of the
            % input format.
            
            if isstruct(frame)
                [height, width, ~] = size(frame(1).cdata);
            else
                [height, width, ~] = size(frame);
            end
        end
    end
    
    methods(Access='private', Hidden)
        function fileName = getFileName(obj)
            fileName = [obj.Path filesep obj.Name];
        end
        
        function writeHeader(obj)
            %writes a typical header for SPE-files (4100 bytes of nothing)
            fd = obj.FileIdentifier;
            frewind(fd); %assert to be at start of the file
            headerstop = hex2dec('1004'); %bytes inside file:
            header = zeros(headerstop,1);
            fwrite(fd, header, 'ubit8'); %zeros of headersize
            %write some basic properties into the header:
            %version number (version 2)--version 3 not yet implemented
            fseek(fd, hex2dec('7C8'), 'bof');
            fwrite(fd, 2, 'single');
            %last value in header--
            fseek(fd, hex2dec('1002'), 'bof');
            fwrite(fd, hex2dec('5555'), 'int16');
            %old number of scans (obsolete, but must be included)--
            fseek(fd, hex2dec('22'), 'bof');
            fwrite(fd, -1, 'int16');
            %mark this file as being created in winx--
            fseek(fd, hex2dec('BB4'), 'bof');
            fwrite(fd, hex2dec('1234567'), 'int32');
            %number of scans (not set by default)--
            fseek(fd, hex2dec('298'), 'bof');
            fwrite(fd, -1, 'int32');
            %is signal not scrambled? (default unscrambled)--
            fseek(fd, hex2dec('292'), 'bof');
            fwrite(fd, 1, 'int16');
            %write frame related stuff:
            obj.writeFrameNR;
        end
        
        function writeFrameNR(obj)
            %update framenumber in header block on current frames in file
            frames = obj.FrameCount;
            fd = obj.FileIdentifier;
            fseek(fd, hex2dec('5A6'), 'bof');
            fwrite(fd,frames,'uint32');
        end
        
        function writeFrames(obj, frames)
            % Write image frames to the file.
            
            % Figure out the allowed data types for the profile and
            % determine if the supplied image is of an allowable type.
            dataType = class(frames);
            
            allowedDataType = obj.EnforcedDataType;
            if isempty(allowedDataType)
                %enforced datatype not set, so check if current datatype is suitable:
                try
                    SpeReader.getDataTypeId(dataType); %if not found, it will die
                    obj.EnforcedDataType = dataType; %dataType ok, so enforce!
                    allowedDataType = dataType;
                catch exception %#ok<NASGU>
                    %show all possible values:
                    allowedDataType = SpeReader.DataType.keys;
                end
            end
            
            
            if ~any(strcmp(dataType, allowedDataType))
                error(['source was of invalid datatype:' dataType ' (required:' allowedDataType ')']);
            end
            
            numFrames = size(frames, 4);
            %convert frames to 1 channel:
            if size(frames, 3) > 1
                frames = mean(frames,3); %take mean of colorchannels
                cast(frames,dataType); %cast result back into desired dataType
            end
            frameCount = obj.FrameCount;
            fd = obj.FileIdentifier;
            if frameCount <= 0
                height = size(frames,1);
                %write height to file and object (twice)
                fseek(fd, hex2dec('2A'), 'bof');
                fwrite(fd,height,'uint16');
                fseek(fd, hex2dec('6'), 'bof');
                fwrite(fd,height,'uint16');
                obj.Height = height;
                
                width = size(frames,2);
                %write width to file and object (twice)
                fseek(fd, hex2dec('290'), 'bof');
                fwrite(fd,width,'uint16');
                fseek(fd, hex2dec('12'), 'bof');
                fwrite(fd,height,'uint16');
                obj.Width = width;
                
                %write also the dataType:
                dataTypeId = SpeReader.DataType(obj.EnforcedDataType);
                fseek(fd, hex2dec('6C'), 'bof');
                fwrite(fd, dataTypeId, 'uint16');
            end
            %append contents to file:
            framedump = permute(frames,[2 1 3 4]); %flip x and y
            fseek(fd, 0, 'eof');
            fwrite(fd,framedump,dataType);
            
            %update framecount and number of frames
            obj.FrameCount = frameCount + numFrames;
            obj.writeFrameNR;
        end
        
        function writeFooter(obj)
            %write the footer xml text:
            fd = obj.FileIdentifier;
            fseek(fd, 0, 'eof'); %get end of file:
            footerOffset = ftell(fd);
            footerXml = obj.writeFooterXML;
            fwrite(fd, unicode2native(footerXml'), 'char');
            %write footer offset to the header:
            fseek(fd, hex2dec('2A6'), 'bof');
            fwrite(fd,footerOffset,'uint64');
        end
        
        function xml = writeFooterXML(obj)
            % Get amount of bytes the image is represented by:
            dataByte = zeros(1,obj.EnforcedDataType); %#ok<NASGU>
            dataProps = whos('dataByte');
            datasize = dataProps.bytes*obj.Height*obj.Width;
            %build XML:
            xml = [ '<SpeFormat version="3.0" xmlns="http://www.princetoninstruments.com/spe/2009">'...
                    '<DataFormat>'...
                    '<DataBlock type="Frame" '...
                                'count="' num2str(obj.FrameCount) '" '... 
                                'pixelFormat="' obj.getPixelFormat '" '...
                                'size="' num2str(datasize) '" '...
                                'stride="' num2str(datasize) '">'...
                    '<DataBlock type="Region" '...
                                'count="1" '...
                                'width="' num2str(obj.Height) '" '...
                                'height="' num2str(obj.Width) '" '...
                                'size="' num2str(datasize) '" '...
                                'stride="' num2str(datasize) '" />'...
                    '</DataBlock>'...
                    '</DataFormat>'...
                    '</SpeFormat>'];
        end
        
        function pixelFormat = getPixelFormat(obj)
            dataType = obj.EnforcedDataType;
            if ~isempty(dataType)
                pixelColor = 'Monochrome';
                if strcmp(dataType(1:3),'int')
                    pixelType = 'Signed';
                elseif strcmp(dataType(1:4),'uint')
                    pixelType = 'Unsigned';
                else
                    pixelType = 'Floating';
                end
                dataByte = zeros(1,dataType); %#ok<NASGU>
                dataProps = whos('dataByte');
                pixelBit = dataProps.bytes*8;
                pixelFormat = [pixelColor pixelType num2str(pixelBit)];
            end
        end
        
    end
    
    methods
        % Properties that need to be customly get or set
        function set.Tag(obj, value)
            if ~(ischar(value) || isempty(value))
                error('Tag must be a string value!');
            end
            obj.Tag = value;
        end
        
        function value = get.Type(obj)
            value = class(obj);
        end
        
    end
end