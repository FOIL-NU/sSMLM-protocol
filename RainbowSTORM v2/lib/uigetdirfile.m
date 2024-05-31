function fName = uigetdirfile(defaultPath)

if nargin < 1
    defaultPath = pwd;
end

jFC = javax.swing.JFileChooser(defaultPath);
jFC.setFileSelectionMode(jFC.FILES_AND_DIRECTORIES);
jFC.setMultiSelectionEnabled(true);
% filter files to only show .csv, .tif, .nd2 files
jFC.setFileFilter(javax.swing.filechooser.FileNameExtensionFilter(...
    'Supported Formats', {'csv', 'tif', 'nd2'}));

returnVal = jFC.showOpenDialog([]);
switch returnVal
    case jFC.APPROVE_OPTION
        % if there are multiple files, return a cell array
        if jFC.getSelectedFiles().length > 1
            fName = cell(jFC.getSelectedFiles());
        else
            fName = string(jFC.getSelectedFile());
        end

        % if there are multiple files, convert the elements in the cell array 
        % to a string array
        if iscell(fName)
            fName = string(fName);
        end

    case jFC.CANCEL_OPTION
        fName = [];
    case jFC.ERROR_OPTION
        fName = [];
    otherwise
        throw(MException("fileFolderChooser:unsupportedResult", ...
            "Unsupported result returned from JFileChooser: " + returnVal + ...
            ". Please consult the documentation of the current Java version (" + ...
            string(java.lang.System.getProperty("java.version")) + ")."));
end

% %% Process selection:
% switch true % < this is just some trick to avoid if/elseif
%   case isfolder(fName)
%     % Do something with folder
%   case isfile(fName)
%     % Do something with file
%   otherwise
%     throw(MException('fileFolderChooser:invalidSelection',...
%                      'Invalid selection, cannot proceed!'));
% end