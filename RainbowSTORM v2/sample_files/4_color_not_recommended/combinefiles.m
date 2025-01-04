function combinefiles(outputFileName, varargin)
combinedData = [];
for k = 1:length(varargin)
    filePattern = sprintf('%s_*.csv', varargin{k});
    files = dir(filePattern);
    for i = 1:length(files)
        tempData = readtable(files(i).name, 'PreserveVariableNames', true);
        combinedData = [combinedData; tempData];
    end
end
writetable(combinedData, outputFileName);
end