function roi_crop(in_csv_path, out_csv_path, roi_file, magnification_factor, px_size)
% add the roi helper function to the path
addpath('../lib/'); % needed for the ReadImageJROI function

% read in the csv file
data = readtable(in_csv_path, 'preservevariablenames', true);

% read in the roi file
roi = ReadImageJROI(roi_file);

% we get the coordinates of x and y in data that are within the roi coordinates
points_within = inpolygon(data{:, 'x [nm]'} / (px_size / magnification_factor), ...
    data{:, 'y [nm]'} / (px_size / magnification_factor), ...
    roi.mnCoordinates(:, 1), roi.mnCoordinates(:, 2));

% prepare the output csv
out_data = data(points_within, :);

% write the output csv
writetable(out_data, out_csv_path);