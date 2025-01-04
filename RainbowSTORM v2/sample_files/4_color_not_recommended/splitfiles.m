function splitfiles(maxSizeMB, varargin)
% sample usage:
%   splitfiles(60, 'p750p019_zeroth', 'p750p019_first');

% Process multiple files provided in varargin
for k = 1:length(varargin)
    fname = sprintf('%s.csv', varargin{k});
    opts = detectImportOptions(fname, 'PreserveVariableNames', true);

    % Force all variables to be imported as double
    opts.VariableTypes(:) = {'double'}; 

    % Read table with enforced types
    data = readtable(fname, opts);

    splitAndSaveDataBySize(data, varargin{k}, maxSizeMB);
end
end

% Nested function to split and save data based on file size limit
function splitAndSaveDataBySize(data, baseName, maxSizeMB)
% Estimate size per row based on data types and columns
varTypes = varfun(@class, data, 'OutputFormat', 'cell');
bytesPerColumn = containers.Map({'double', 'single', 'int32', 'int16', 'int8', 'char', 'string'}, ...
    [8, 4, 4, 2, 1, 1, 2]); % Byte sizes
estRowSize = sum(cellfun(@(x) bytesPerColumn(x), varTypes));
estRowSize = estRowSize + numel(varTypes); % Account for delimiters

maxRowsPerFile = floor((maxSizeMB * 1024 * 1024) / estRowSize); % Calculate rows per file
numChunks = ceil(height(data) / maxRowsPerFile);

for i = 1:numChunks
    savefile = sprintf('%s_%d.csv', baseName, i);
    startIdx = (i - 1) * maxRowsPerFile + 1;
    endIdx = min(i * maxRowsPerFile, height(data));
    writetable(data(startIdx:endIdx, :), savefile);
end
end
