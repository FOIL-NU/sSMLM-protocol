function [ts_output, recon_im] = processfile_core(csvpath_0, csvpath_1, img_type, calipath, varargin)
% process files v3
% upgraded to use the spectral calibration file to do initial matching of the points

% create an input parser
parser = inputParser;

% define the default values
default_central_wavelength = 680;
default_corr_pxsz = 10;
default_recon_pxsz = 20;
default_zcali_path = '';
default_plot_hist = false;
default_num_passes = 2;
default_order0_crops = [0, 0, 0, 0];
default_order1_crops = [0, 0, 0, 0];

% define the optional parameters
addParameter(parser, 'central_wavelength', default_central_wavelength, @isnumeric);
addParameter(parser, 'corr_pxsz', default_corr_pxsz, @isnumeric);
addParameter(parser, 'recon_pxsz', default_recon_pxsz, @isnumeric);
addParameter(parser, 'zcali_path', default_zcali_path, @ischar);
addParameter(parser, 'plot_hist', default_plot_hist, @islogical);
addParameter(parser, 'num_passes', default_num_passes, @isnumeric);
addParameter(parser, 'order0_crops', default_order0_crops, @isnumeric);
addParameter(parser, 'order1_crops', default_order1_crops, @isnumeric);

% parse the input
parse(parser, varargin{:});

% extract the optional parameters
% central_wavelength = parser.Results.central_wavelength;
corr_pxsz = parser.Results.corr_pxsz;
recon_pxsz = parser.Results.recon_pxsz;
zcali_path = parser.Results.zcali_path;
plot_hist = parser.Results.plot_hist;
num_passes = parser.Results.num_passes;
% order0_crops = parser.Results.order0_crops;
% order1_crops = parser.Results.order1_crops;

if nargin < 4
    error('specify the path to the spectral calibration file');
else
    load(calipath,'speccali');
    % check if the calibration file has the correct fields
    if ~isfield(speccali, 'fx')
        error('calibration file must have fx field');
    end
    if ~isfield(speccali, 'fy')
        error('calibration file must have fy field');
    end
    if ~isfield(speccali, 'tform_mean')
        error('calibration file must have tform_mean field');
    end
    if ~isfield(speccali, 'xshift_mean')
        error('calibration file must have xshift_mean field');
    end
    if ~isfield(speccali, 'yshift_mean')
        error('calibration file must have yshift_mean field');
    end
    if ~isfield(speccali, 'wavelengths')
        error('calibration file must have wavelengths field');
    end
end

if nargin < 3
    error('specify image type');
else
    % check if img_type is a string
    if ~ischar(img_type)
        error('img_type must be a string');
    end
    assert(strcmpi(img_type, 'sdwp') || strcmpi(img_type, 'odwp'), ...
        'img_type must be either sdwp or odwp');
end

if nargin < 2
    error('specify csv path for 1st order');
else
    % check if csvpath_1 is a csv file
    if ~endsWith(csvpath_1, '.csv')
        % append .csv to the end of the file
        csvpath_1 = [csvpath_1, '.csv'];
    end
    assert(exist(csvpath_1, 'file') == 2, 'csvpath_1 does not exist');
end

if nargin < 1
    error('specify csv path for 0th order');
else
    % check if csvpath_0 is a csv file
    if ~endsWith(csvpath_0, '.csv')
        % append .csv to the end of the file
        csvpath_0 = [csvpath_0, '.csv'];
    end
    assert(exist(csvpath_0, 'file') == 2, 'csvpath_0 does not exist');
end

% print that reading the csv files
fprintf('Reading the csv files...\n');
ts_table0 = readtable(csvpath_0,'preservevariablenames',true);
ts_table1 = readtable(csvpath_1,'preservevariablenames',true);

% correct the x and y values of the 1st order
[xcomp, ycomp] = corr_xy(ts_table0, ts_table1, corr_pxsz);

% correct the x1 and y1 values with tform_mean and fx at the central_wavelength,
% yshift_mean
ts_table1{:, 'x [nm]'} = ts_table1{:, 'x [nm]'} + xcomp;
ts_table1{:, 'y [nm]'} = ts_table1{:, 'y [nm]'} + ycomp;
% correct for magnification/distortion errors with tform_mean

if isMATLABReleaseOlderThan('R2022b')
    [ts_table1{:, 'x [nm]'}, ts_table1{:, 'y [nm]'}] = ...
        transformPointsForward(affine2d(speccali.tform_mean), ...
        ts_table1{:, 'x [nm]'}, ts_table1{:, 'y [nm]'});
else
    [ts_table1{:, 'x [nm]'}, ts_table1{:, 'y [nm]'}] = ...
        transformPointsForward(affinetform2d(speccali.tform_mean'), ...
        ts_table1{:, 'x [nm]'}, ts_table1{:, 'y [nm]'});
end

% correct the x and y values of the 1st order again
[xcomp, ycomp] = corr_xy(ts_table0, ts_table1, corr_pxsz);

% correct the x1 and y1 values with tform_mean and fx at the central_wavelength,
% yshift_mean
ts_table1{:, 'x [nm]'} = ts_table1{:, 'x [nm]'} + xcomp;
ts_table1{:, 'y [nm]'} = ts_table1{:, 'y [nm]'} + ycomp;

% sort the tables by frame
ts_table0 = sortrows(ts_table0, 'frame');
ts_table1 = sortrows(ts_table1, 'frame');

if num_passes > 1
    fprintf('Pass 1...\n');
    [matched_idx0, matched_idx1] = matchlocalizations(ts_table0, ts_table1);

    % filter the localizations by the matched indices
    tsnew_table0 = ts_table0(ismember(ts_table0{:, 'id'}, matched_idx0), :);
    tsnew_table1 = ts_table1(ismember(ts_table1{:, 'id'}, matched_idx1), :);
        
    % filter the localizations where abs(y_1 - y_0) < 450 and abs(x_1 - x_0) < 2200
    sel = (abs(tsnew_table1{:, 'y [nm]'} - tsnew_table0{:, 'y [nm]'}) < 450) & ...
        (abs(tsnew_table1{:, 'x [nm]'} - tsnew_table0{:, 'x [nm]'}) < 2200);

    tsnew_table0 = tsnew_table0(sel, :);
    tsnew_table1 = tsnew_table1(sel, :);

    % correct the x_comp and y_comp values a second time
    fitx_params = fitdist(rmoutliers(tsnew_table1{:,'x [nm]'} - tsnew_table0{:,'x [nm]'}), 'normal');
    fity_params = fitdist(rmoutliers(tsnew_table1{:,'y [nm]'} - tsnew_table0{:,'y [nm]'}), 'normal');

    clear('tsnew_table0', 'tsnew_table1');

    xcomp2 = fitx_params.mu;
    ycomp2 = fity_params.mu;

    ts_table1{:,'x [nm]'} = ts_table1{:,'x [nm]'} - xcomp2;
    ts_table1{:,'y [nm]'} = ts_table1{:,'y [nm]'} - ycomp2;
    
    fprintf('Pass 2...\n');
    [matched_idx0, matched_idx1] = matchlocalizations(ts_table0, ts_table1);

    % filter the localizations by the matched indices
    tsnew_table0 = ts_table0(ismember(ts_table0{:, 'id'}, matched_idx0), :);
    tsnew_table1 = ts_table1(ismember(ts_table1{:, 'id'}, matched_idx1), :);
else
    [matched_idx0, matched_idx1] = matchlocalizations(ts_table0, ts_table1);

    % filter the localizations by the matched indices
    tsnew_table0 = ts_table0(ismember(ts_table0{:, 'id'}, matched_idx0), :);
    tsnew_table1 = ts_table1(ismember(ts_table1{:, 'id'}, matched_idx1), :);
end

% filter the localizations where abs(y_1 - y_0) < 450 and abs(x_1 - x_0) < 2200
sel = (abs(tsnew_table1{:, 'y [nm]'} - tsnew_table0{:, 'y [nm]'}) < 450) & ...
    (abs(tsnew_table1{:, 'x [nm]'} - tsnew_table0{:, 'x [nm]'}) < 2200);

if plot_hist == true
    % analyze the matching histograms after filtering
    figure(1); clf;
    subplot(2,2,1); hold on;
    histogram(tsnew_table1{:,'x [nm]'} - tsnew_table0{:,'x [nm]'},'binwidth',10);
    xlabel('x position (nm)');
    ylabel('count');
    title('x position histograms');

    subplot(2,2,3); hold on;
    histogram(tsnew_table1{:,'y [nm]'} - tsnew_table0{:,'y [nm]'},'binwidth',10);
    xlabel('y position (nm)');
    ylabel('count');
    title('y position histograms');

    tsnew_table0 = tsnew_table0(sel, :);
    tsnew_table1 = tsnew_table1(sel, :);

    subplot(2,2,2); hold on;
    histogram(tsnew_table1{:,'x [nm]'} - tsnew_table0{:,'x [nm]'},'binwidth',10);
    xlabel('x position (nm)');
    ylabel('count');
    title('x position histograms');

    subplot(2,2,4); hold on;
    histogram(tsnew_table1{:,'y [nm]'} - tsnew_table0{:,'y [nm]'},'binwidth',10);
    xlabel('y position (nm)');
    ylabel('count');
    title('y position histograms');
end

% prepare the output file

% make a new table with the following headers:
% id, frame, x [nm], y [nm], z [nm], centroid [nm], sigmax0 [nm], ...
% sigmay0 [nm], sigmax1 [nm], sigmay1 [nm], uncertainty [nm], ...
% uncertainty0 [nm], uncertainty1 [nm], intensity [photon], ...
% intensity0 [photon], intensity1 [photon], offset [photon], ...
% offset0 [photon],  offset1 [photon], bkgstd [photon], ...
% bkgstd0 [photon], bkgstd1 [photon]

ts_output = table('Size', [length(tsnew_table0{:, 'frame'}), 22], ...
    'VariableNames', {'id', 'frame', ...
    'x [nm]', 'y [nm]', 'z [nm]', 'centroid [nm]', ...
    'sigmax0 [nm]', 'sigmay0 [nm]', 'sigmax1 [nm]', 'sigmay1 [nm]', ...
    'uncertainty [nm]', 'uncertainty0 [nm]', 'uncertainty1 [nm]', ...
    'intensity [photon]', 'intensity0 [photon]', 'intensity1 [photon]', ...
    'offset [photon]', 'offset0 [photon]', 'offset1 [photon]', ...
    'bkgstd [photon]', 'bkgstd0 [photon]', 'bkgstd1 [photon]'}, ...
    'VariableTypes', {'uint32', 'uint32', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double'});

% fill in the values
ts_output{:, 'id'} = (1:length(tsnew_table0{:, 'frame'}))';
ts_output{:, 'frame'} = tsnew_table0{:, 'frame'};

if strcmpi(img_type, 'sdwp')
    ts_output{:, 'x [nm]'} = (tsnew_table0{:, 'x [nm]'} + ...
        tsnew_table1{:, 'x [nm]'}) / 2;
    ts_output{:, 'y [nm]'} = (tsnew_table0{:, 'y [nm]'} + ...
        tsnew_table1{:, 'y [nm]'}) / 2;
elseif strcmpi(img_type, 'odwp')
    ts_output{:, 'x [nm]'} = tsnew_table0{:, 'x [nm]'};
    ts_output{:, 'y [nm]'} = tsnew_table0{:, 'y [nm]'};
else
    error('img_type must be either sdwp or odwp');
end

if ~isempty(zcali_path)
    if ismember('sigma2 [nm]', tsnew_table0.Properties.VariableNames)
        temp_sigma0 = tsnew_table0{:, 'sigma2 [nm]'};
    else
        temp_sigma0 = tsnew_table0{:, 'sigma [nm]'};
    end
    
    if ismember('sigma2 [nm]', tsnew_table1.Properties.VariableNames)
        temp_sigma1 = tsnew_table1{:, 'sigma2 [nm]'};
    else
        temp_sigma1 = tsnew_table1{:, 'sigma [nm]'};
    end
    
    ts_output{:, 'z [nm]'} = getz(temp_sigma0, temp_sigma1, zcali_path);
else
    ts_output{:, 'z [nm]'} = nan(length(tsnew_table0{:, 'frame'}), 1);
end

ts_output{:, 'centroid [nm]'} = tsnew_table1{:, 'x [nm]'} - ...
    tsnew_table0{:, 'x [nm]'};

if ismember('sigma1 [nm]', tsnew_table0.Properties.VariableNames)
    ts_output{:, 'sigmax0 [nm]'} = tsnew_table0{:, 'sigma1 [nm]'};
    ts_output{:, 'sigmay0 [nm]'} = tsnew_table0{:, 'sigma2 [nm]'};
else
    ts_output{:, 'sigmax0 [nm]'} = tsnew_table0{:, 'sigma [nm]'};
    ts_output{:, 'sigmay0 [nm]'} = tsnew_table0{:, 'sigma [nm]'};
end

if ismember('sigma1 [nm]', tsnew_table1.Properties.VariableNames)
    ts_output{:, 'sigmax1 [nm]'} = tsnew_table1{:, 'sigma1 [nm]'};
    ts_output{:, 'sigmay1 [nm]'} = tsnew_table1{:, 'sigma2 [nm]'};
else
    ts_output{:, 'sigmax1 [nm]'} = tsnew_table1{:, 'sigma [nm]'};
    ts_output{:, 'sigmay1 [nm]'} = tsnew_table1{:, 'sigma [nm]'};
end

ts_output{:, 'uncertainty0 [nm]'} = tsnew_table0{:, 'uncertainty [nm]'};
ts_output{:, 'uncertainty1 [nm]'} = tsnew_table1{:, 'uncertainty [nm]'};
% take the root mean square of the uncertainties
ts_output{:, 'uncertainty [nm]'} = rms([tsnew_table0{:, 'uncertainty [nm]'}, tsnew_table1{:, 'uncertainty [nm]'}], 2);

ts_output{:, 'intensity0 [photon]'} = tsnew_table0{:, 'intensity [photon]'};
ts_output{:, 'intensity1 [photon]'} = tsnew_table1{:, 'intensity [photon]'};
% take the mean of the intensities
ts_output{:, 'intensity [photon]'} = mean([tsnew_table0{:, 'intensity [photon]'}, tsnew_table1{:, 'intensity [photon]'}], 2);

ts_output{:, 'offset0 [photon]'} = tsnew_table0{:, 'offset [photon]'};
ts_output{:, 'offset1 [photon]'} = tsnew_table1{:, 'offset [photon]'};
% take the mean of the offsets
ts_output{:, 'offset [photon]'} = mean([tsnew_table0{:, 'offset [photon]'}, tsnew_table1{:, 'offset [photon]'}], 2);

ts_output{:, 'bkgstd0 [photon]'} = tsnew_table0{:, 'bkgstd [photon]'};
ts_output{:, 'bkgstd1 [photon]'} = tsnew_table1{:, 'bkgstd [photon]'};
% take the mean of the bkgstds
ts_output{:, 'bkgstd [photon]'} = mean([tsnew_table0{:, 'bkgstd [photon]'}, tsnew_table1{:, 'bkgstd [photon]'}], 2);

% generate a reconstructed image
recon_im = ash2(ts_output{:,'x [nm]'}, ts_output{:,'y [nm]'}, recon_pxsz);

end


function [matched_idx0, matched_idx1] = matchlocalizations(ts_table0, ts_table1)
% extract the frames of the tables
frame0 = ts_table0{:, 'frame'};
frame1 = ts_table1{:, 'frame'};

n_frames = max([frame0; frame1]);

% extract the indices of the tables
idx0 = ts_table0{:, 'id'};
idx1 = ts_table1{:, 'id'};

% intialize the variables to store pairs of closest localizations
matched_idx0 = nan(min([length(idx0), length(idx1)]), 1);
matched_idx1 = nan(min([length(idx0), length(idx1)]), 1);
curr_idx = 1;

% print that we are matching the localizations
%upd = textprogressbar(n_frames, 'startmsg', 'Matching localizations: ', 'showbar', true');

for i_frame = 1:n_frames
    % get the localizations in the current frame
    curr_idx0 = find(frame0 == i_frame);
    curr_idx1 = find(frame1 == i_frame);

    % get the temporary index of the current frame
    tmp_idx0 = idx0(curr_idx0);
    tmp_idx1 = idx1(curr_idx1);
    
    % get the x and y coordinates of the current frame
    tmp_x0 = ts_table0{curr_idx0, 'x [nm]'};
    tmp_y0 = ts_table0{curr_idx0, 'y [nm]'};
    tmp_x1 = ts_table1{curr_idx1, 'x [nm]'};
    tmp_y1 = ts_table1{curr_idx1, 'y [nm]'};
    
    % perform knnsearch to find the closest localizations
    knn_idx1 = knnsearch([tmp_x0, tmp_y0], [tmp_x1, tmp_y1], 'k', 1);
    knn_idx0 = knnsearch([tmp_x1, tmp_y1], [tmp_x0, tmp_y0], 'k', 1);

    % find the mutual closest localizations
    if ~isempty(knn_idx0)
        mutual_idx0 = find(knn_idx1(knn_idx0) == (1:length(knn_idx0))');
    else
        mutual_idx0 = [];
    end

    if ~isempty(knn_idx1)
        mutual_idx1 = find(knn_idx0(knn_idx1) == (1:length(knn_idx1))');
    else 
        mutual_idx1 = [];
    end

    if ~isempty(mutual_idx0) && ~isempty(mutual_idx1)
        % assert that the mutual indices have the same length
        assert(length(mutual_idx0) == length(mutual_idx1));
        n_pairs = length(mutual_idx0);
        matched_idx0(curr_idx:(curr_idx+n_pairs-1)) = tmp_idx0(mutual_idx0);
        matched_idx1(curr_idx:(curr_idx+n_pairs-1)) = tmp_idx1(mutual_idx1);
        curr_idx = curr_idx + n_pairs;
    end
    % upd(i_frame);
    
end

% remove the nan values
matched_idx0 = matched_idx0(~isnan(matched_idx0));
matched_idx1 = matched_idx1(~isnan(matched_idx1));

end