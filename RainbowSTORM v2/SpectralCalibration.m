classdef SpectralCalibration < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        GridLayout                  matlab.ui.container.GridLayout
        
            InputBrowseButton           matlab.ui.control.Button

            UITable                     matlab.ui.control.Table
            SaveCalibrationFileButton   matlab.ui.control.Button

            UIAxesXShifts               matlab.ui.control.UIAxes
    end

    properties (Access = public)
        LOCALIZATION_MATCHING = 0;
        IMAGE_MATCHING = 1;

        spectral_calibration_mode

        % Properties that correspond to app components
        dir_inputpath % path to the input directory
        dir_outputpath % path to the output directory
        wavelengths = [532, 580, 633, 680, 750] % wavelengths to be calibrated
        speccali_struct % spectral calibration structure initialization
        files % list of csv files in the input directory

        data

        % other internal properties for plotting the advanced functions
        fx
        fy
        locs0
        locs1
        xscale
        yscale
        xshift
        yshift
        wls
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: InputBrowseButton
        function InputBrowseButtonPushed(app, ~)
            input_dir = uigetdirfile;
            % error handling for cancel button
            if isempty(input_dir)
                return
            end

            if length(input_dir) == 1
                % check if this is a directory
                if isfolder(input_dir)
                    app.dir_inputpath = input_dir;
                else
                    errordlg('Please select a valid input directory.', 'Error');
                    return
                end
                
                csv_files = dir(fullfile(app.dir_inputpath, '*.csv'));
                nd2_files = dir(fullfile(app.dir_inputpath, '*.nd2'));
                tif_files = dir(fullfile(app.dir_inputpath, '*.tif'));

                if isempty(csv_files) && isempty(nd2_files) && isempty(tif_files)
                    errordlg('No valid files found in the input directory. Please select a valid input directory.', 'Error');
                    return
                end
                
                if ~isempty(csv_files)
                    app.spectral_calibration_mode = app.LOCALIZATION_MATCHING;
                else
                    app.spectral_calibration_mode = app.IMAGE_MATCHING;
                end

                app.files = struct2table([csv_files; nd2_files; tif_files], 'AsArray', true);
                
            else % if this is a list of files
                [app.dir_inputpath, ~, ref_ext] = fileparts(input_dir{1});
                if strcmpi(ref_ext, '.csv')
                    app.spectral_calibration_mode = app.LOCALIZATION_MATCHING;
                else
                    app.spectral_calibration_mode = app.IMAGE_MATCHING;
                end

                input_filenames = cell(length(input_dir), 1);
                input_isdir = cellfun(@isfolder, input_dir);
                for ii = 1:length(input_dir)
                    [~, name, ext] = fileparts(input_dir{ii});
                    % assert that all the filenames have the same extension
                    assert(strcmp(ext, ref_ext), 'All the files must have the same extension.');
                    input_filenames{ii} = strcat(name, ext);
                end
                app.files = table(input_filenames, input_isdir, ...
                    'VariableNames', {'name', 'isdir'});
            end
            
            app.dir_outputpath = fullfile(app.dir_inputpath, 'speccali.mat');
            figure(app.UIFigure); % bring the app to the front
            app.UITable.Enable = 'on';
            LoadTable(app);
            app.data = cell(height(app.files), 1);
            LoadData(app);
            RunCalibration(app);
        end

        function LoadTable(app, ~)
            % try to match the files to a wavelength each
            app.files{:, 'wavelength'} = zeros(height(app.files), 1);
            
            % if there are fewer files than wavelengths, we trim the wavelength array
            if height(app.files) < length(app.wavelengths)
                app.wavelengths = app.wavelengths(1:height(app.files));
            end

            app.files{1:length(app.wavelengths), 'wavelength'} = app.wavelengths(:);

            % update the UITable with the filenames and wavelengths
            app.UITable.Data = app.files(:, {'name', 'wavelength'});

            % check if we have any empty cells in the table
            if any((app.UITable.Data{:, 2}) == 0)
                % Some wavelengths could not be matched to the csv files.
                return
            end
        end

        function LoadData(app, idx)
            if nargin > 1
                load_data(app, idx);
            else
                % load all the data
                for idx = 1:height(app.files)
                    load_data(app, idx);
                end
            end
        end

        function RunCalibration(app, ~)
            % calculate the spectral calibration and plot the results
            if app.spectral_calibration_mode == app.LOCALIZATION_MATCHING
                speccali_localizations(app);
            elseif app.spectral_calibration_mode == app.IMAGE_MATCHING
                speccali_correlations(app);
            end
            updateUIAxesXShifts(app);
            
            app.SaveCalibrationFileButton.Enable = 'on';
        end

        function AdvancedViewButtonPushed(app, ~)
            if app.AdvancedViewButton.Value
                % expand the gui to show the additional plots at the bottom
                app.UIFigure.Position(4) = 640;

            else
                % condense the gui to hide the additional plots at the bottom
                app.UIFigure.Position(4) = 300;
            end
        end

        % Button pushed function: OutputBrowseButton
        function OutputBrowseButtonPushed(app, ~)
            [file,output_path] = uiputfile('*.mat');
            % error handling for cancel button
            if ~output_path
                return
            end
            app.dir_outputpath = fullfile(output_path, file);
            app.OutputFileTextArea.Value = app.dir_outputpath;
        end

        % When the wavelength in the UITable is edited
        function UITableCellEdit(app, event)
            % get the row and column of the edited cell
            row = event.Indices(1);
            col = event.Indices(2);

            % get the selected wavelengths
            selected_wavelengths = app.UITable.Data{:, 2};
            % error handling for no wavelengths selected
            if sum(selected_wavelengths > 0) < 2
                errordlg('Insufficient wavelengths selected. Please input at least two wwavelengths.', 'Error');
                return
            end

            if col == 1
                if isempty(app.UITable.Data{row, 1})
                    app.UITable.Data(row, :) = [];
                else
                    % check if the file exists
                    if ~isfile(fullfile(app.dir_inputpath, app.UITable.Data{row, 1}))
                        errordlg('The file does not exist. Please select a valid file.', 'Error');
                        % app.UITable.Data(row, col) = 'invalid file'
                        return
                    end

                    % update the filename in the table
                    app.files{row, 'name'} = app.UITable.Data{row, 1};

                    % load the data from the file
                    LoadData(app, row);
                end
            elseif col == 2
                if (app.UITable.Data{row, 2} == 0) || isnan(app.UITable.Data{row, 2})
                    app.UITable.Data(row, :) = [];
                end
            end

            RunCalibration(app);
        end

        % update UIAxesXShifts with the x-shift vs wavelength
        function updateUIAxesXShifts(app, ~)
            if ~isstruct(app.speccali_struct)
                return
            end
            cla(app.UIAxesXShifts);
            plot(app.UIAxesXShifts, app.speccali_struct.wavelengths, app.speccali_struct.xshift, 'ko');
            hold(app.UIAxesXShifts, 'on');
            wavelength_fine = linspace(min(app.speccali_struct.wavelengths),max(app.speccali_struct.wavelengths),101);
            plot(app.UIAxesXShifts, wavelength_fine, dwp_wl2px(wavelength_fine, app.speccali_struct.fx), 'k-')
            hold(app.UIAxesXShifts, 'off');
            xlabel(app.UIAxesXShifts, 'wavelength (nm)');
            ylabel(app.UIAxesXShifts, 'x shift (nm)');
        end

        % update UIAxesYShifts with the y-shift vs wavelength
        function updateUIAxesYShifts(app, ~)
            if ~isstruct(app.speccali_struct)
                return
            end

            plot(app.UIAxesYShifts, app.speccali_struct.wavelengths, app.speccali_struct.yshift, 'ko');
            hold(app.UIAxesYShifts, 'on');
            wavelength_fine = linspace(min(app.speccali_struct.wavelengths),max(app.speccali_struct.wavelengths),101);
            plot(app.UIAxesYShifts, wavelength_fine, dwp_wl2px(wavelength_fine, app.speccali_struct.fy), 'k-')
            hold(app.UIAxesYShifts, 'off');
            xlabel(app.UIAxesYShifts, 'wavelength (nm)');
            ylabel(app.UIAxesYShifts, 'y shift (nm)');
        end

        % Button pushed function: SaveCalibrationFileButton
        function SaveCalibrationFileButtonPushed(app, ~)
            % get the output file path from the user
            [file,output_path] = uiputfile({'*.mat', 'MAT-files (*.mat)'}, 'Save Calibration File', app.dir_outputpath);

            % error handling for cancel button
            if ~output_path
                return
            end

            app.dir_outputpath = fullfile(output_path, file);

            % save the calibration file
            speccali = app.speccali_struct;
            save(app.dir_outputpath, 'speccali');
            
            % send an event to the app
            eventdata = eventsetfilename(app.dir_outputpath);
            notify(app, 'CalibrationFileSaved', eventdata);
        end

        function load_data(app, ifile)
            app.InputBrowseButton.Enable = 'off';
            app.InputBrowseButton.Text = 'Loading...';
            drawnow;

            % get the filename
            filename = app.files{ifile, 'name'}{:};

            % split the filename to get the extension
            [~, ~, ext] = fileparts(filename);

            if strcmpi(ext, '.csv')
                % load the data from the csv file
                csvdata = readtable(fullfile(app.dir_inputpath, filename), 'preservevariablenames', true);
                app.data{ifile} = csvdata;
            else
                % load the data from the nd2 file
                img = bfOpen3DVolume(char(fullfile(app.dir_inputpath, filename)));
                if isnumeric(img{1}{1})
                    img = img{1}{1};
                end
                app.data{ifile} = mean(squeeze(img), 3);
            end

            app.InputBrowseButton.Enable = 'on';
            app.InputBrowseButton.Text = 'Browse';
        end

        % Core app for spectral calibration
        function speccali_localizations(app, ~)
            file_table = app.UITable.Data;

            nfiles = height(file_table);
            
            % get a reference file for the number of localizations
            csvdata = app.data{1};
            nlocs = height(csvdata);
            app.xshift = zeros(nfiles,1);
            app.yshift = zeros(nfiles,1);
            wls_temp = file_table{:, 'wavelength'};
            app.wls = wls_temp(:)';
            
            assert(mod(nlocs, 2) == 0, 'The number of localizations in the csv files must be even, i.e. the number of zeroth and first order localizations must be equal.');
            app.locs0 = zeros(nfiles,floor(nlocs/2),2);
            app.locs1 = zeros(nfiles,floor(nlocs/2),2);

            for ifile = 1:nfiles
                csvdata = app.data{ifile};
                % check that the number of localization is the same as the reference file
                assert(height(csvdata) == nlocs, 'The number of localizations in the %dth file is not the same as the first file.', ifile);
            
                % split the localizations by order, localizations with x values < x_mean are 0th order, and > x_mean are 1st order
                order_mean = mean(csvdata{:, 'x [nm]'});
                order0 = csvdata(csvdata{:, 'x [nm]'} < order_mean, :);
                order1 = csvdata(csvdata{:, 'x [nm]'} > order_mean, :);
            
                % get the number of localizations
                n0 = height(order0);
                n1 = height(order1);
            
                assert(n0 == n1, 'The number of localizations in the zeroth and first order are not the same.');
            
                % get the mean values of the localizations
                x0 = mean(order0{:, 'x [nm]'});
                y0 = mean(order0{:, 'y [nm]'});
                x1 = mean(order1{:, 'x [nm]'});
                y1 = mean(order1{:, 'y [nm]'});
            
                % correct the shift to find the magnification factors
                app.xshift(ifile) = x1 - x0;
                app.yshift(ifile) = y1 - y0;
                
                app.locs0(ifile,:,:) = order0{:, {'x [nm]', 'y [nm]'}};
                app.locs1(ifile,:,:) = order1{:, {'x [nm]', 'y [nm]'}};
            end

            compute_calibration_curve(app);
            compute_scaling(app);
            prepare_output(app);
        end

        function speccali_correlations(app, ~)
            file_table = app.UITable.Data;

            wls_temp = file_table{:, 'wavelength'};
            app.wls = wls_temp(:)';

            nfiles = height(file_table);

            for ifile = 1:nfiles
                disp('Processing file: ' + string(ifile) + ' of ' + string(nfiles) + '...');
                img = app.data{ifile};

                im_width = size(img, 2);
                im_center_mask = 200;

                im0_roi_xmin = 1;
                im0_roi_xmax = floor(im_width/2)-im_center_mask;
                im1_roi_xmin = floor(im_width/2)+1+im_center_mask;
                im1_roi_xmax = im_width;

                im0 = img(:, im0_roi_xmin:im0_roi_xmax);
                im1 = img(:, im1_roi_xmin:im1_roi_xmax);

                im0 = im0 - min(im0(:));
                im0 = im0 / max(im0(:));
                im1 = im1 - min(im1(:));
                im1 = im1 / max(im1(:));
                gaussfiltsigma = 0;

                imcorr = normxcorr2(im0, im1);
                if gaussfiltsigma>0
                    imcorr = imgaussfilt(imcorr, gaussfiltsigma);
                end
                imcorr_temp = imcorr;
                imcorr = zeros(size(imcorr_temp));
                % we take the middle part of the image
                imcorr_middle_radius = 200;

                imcorr_roi_xmin = floor(size(imcorr_temp, 2)/2 - imcorr_middle_radius);
                imcorr_roi_xmax = ceil(size(imcorr_temp, 2)/2 + imcorr_middle_radius);
                imcorr_roi_ymin = floor(size(imcorr_temp, 1)/2 - imcorr_middle_radius);
                imcorr_roi_ymax = ceil(size(imcorr_temp, 1)/2 + imcorr_middle_radius);

                imcorr(imcorr_roi_ymin:imcorr_roi_ymax, imcorr_roi_xmin:imcorr_roi_xmax) = imcorr_temp(imcorr_roi_ymin:imcorr_roi_ymax, imcorr_roi_xmin:imcorr_roi_xmax);

                [ypeak, xpeak] = find(imcorr == max(imcorr(:)));
                xoffset = xpeak - size(im1,2);
                yoffset = ypeak - size(im1,1);
                
                app.xshift(ifile) = xoffset - im0_roi_xmin + im1_roi_xmin - 1;
                app.yshift(ifile) = yoffset;
            end

            app.xscale = ones(nfiles, 1);
            app.yscale = ones(nfiles, 1);

            compute_calibration_curve(app);
            prepare_output(app);
        end

        function compute_calibration_curve(app, ~)
            app.fx = dwp_fit(app.wls, app.xshift);
            app.fy = dwp_fit(app.wls, app.yshift);
        end

        function prepare_output(app, ~)
            % prepare the output structure
            speccali.xscale = app.xscale;
            speccali.yscale = app.yscale;
            speccali.xshift = app.xshift;
            speccali.yshift = app.yshift;
            speccali.xshift_mean = mean(app.xshift);
            speccali.yshift_mean = mean(app.yshift);
            speccali.fx = app.fx;
            speccali.fy = app.fy;
            speccali.wavelengths = app.wls;

            app.speccali_struct = speccali;
        end

        function compute_scaling(app, ~)
            file_table = app.UITable.Data;
            nfiles = height(file_table);
            
            for ifile = 1:nfiles
                % here we want to calculate the magnification factors in the x and y directions
                % we first match the localizations of the zeroth and first order
                % then we calculate the magnification factors

                % subtract the (expected) shift from the x and y values
                expected_xshift = dwp_wl2px(app.wls(ifile), app.fx);
                expected_yshift = dwp_wl2px(app.wls(ifile), app.fy);

                app.locs1(ifile, :, 1) = app.locs1(ifile, :, 1) - expected_xshift;
                app.locs1(ifile, :, 2) = app.locs1(ifile, :, 2) - expected_yshift;

                [matched_locs0, matched_locs1] = match_localizations(app, ifile);

                % get the linear fit
                px = polyfit(matched_locs0(:, 1), matched_locs1(:, 1), 1);
                py = polyfit(matched_locs0(:, 2), matched_locs1(:, 2), 1);

                app.xscale(ifile) = px(1);
                app.yscale(ifile) = py(1);
            end
        end

        function [matched_locs0, matched_locs1] = match_localizations(app, ifile)
            % intialize the variables to store pairs of closest localizations
            matched_idx0 = nan(min([size(app.locs0,2), size(app.locs1,2)]), 1);
            matched_idx1 = matched_idx0;
            
            % get the x and y coordinates of the current frame
            tmp_x0 = app.locs0(ifile, :, 1);
            tmp_y0 = app.locs0(ifile, :, 2);
            tmp_x1 = app.locs1(ifile, :, 1);
            tmp_y1 = app.locs1(ifile, :, 2);
            
            % get a temporary index
            tmp_idx0 = 1:size(app.locs0, 2);
            tmp_idx1 = 1:size(app.locs1, 2);
            
            % perform knnsearch to find the closest localizations
            knn_idx1 = knnsearch([tmp_x0(:), tmp_y0(:)], [tmp_x1(:), tmp_y1(:)], 'k', 1);
            knn_idx0 = knnsearch([tmp_x1(:), tmp_y1(:)], [tmp_x0(:), tmp_y0(:)], 'k', 1);
            
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
                matched_idx0 = tmp_idx0(mutual_idx0);
                matched_idx1 = tmp_idx1(mutual_idx1);
            end
            
            % remove the nan values
            matched_idx0 = matched_idx0(~isnan(matched_idx0));
            matched_idx1 = matched_idx1(~isnan(matched_idx1));
                
            matched_locs0 = squeeze(app.locs0(ifile, matched_idx0, :));
            matched_locs1 = squeeze(app.locs1(ifile, matched_idx1, :));
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 300];
            app.UIFigure.Name = 'Spectral Calibration';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'3x', '4x'};
            app.GridLayout.RowHeight = {35, '1x', 35};
            app.GridLayout.RowSpacing = 5;


            % Create InputBrowseButton
            app.InputBrowseButton = uibutton(app.GridLayout, 'push');
            app.InputBrowseButton.Layout.Row = 1;
            app.InputBrowseButton.Layout.Column = 1;
            app.InputBrowseButton.Text = 'Browse';
            app.InputBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @InputBrowseButtonPushed, true);

            % Create UITable
            app.UITable = uitable(app.GridLayout);
            app.UITable.ColumnName = {'Filename'; 'Wavelength (nm)'};
            app.UITable.ColumnWidth = {'1x', '1x'};
            app.UITable.RowName = {};
            app.UITable.Layout.Row = 2;
            app.UITable.Layout.Column = 1;
            app.UITable.ColumnEditable = [true, true];
            app.UITable.CellEditCallback = createCallbackFcn(app, @UITableCellEdit, true);
            app.UITable.Enable = 'off';

            % Create SaveCalibrationFileButton
            app.SaveCalibrationFileButton = uibutton(app.GridLayout, 'push');
            app.SaveCalibrationFileButton.Layout.Row = 3;
            app.SaveCalibrationFileButton.Layout.Column = 1;
            app.SaveCalibrationFileButton.Text = 'Save Calibration File';
            app.SaveCalibrationFileButton.ButtonPushedFcn = createCallbackFcn(app, @SaveCalibrationFileButtonPushed, true);
            app.SaveCalibrationFileButton.Enable = 'off';

            % Create UIAxesXShifts
            app.UIAxesXShifts = uiaxes(app.GridLayout);
            app.UIAxesXShifts.Layout.Row = [1 3];
            app.UIAxesXShifts.Layout.Column = 2;
            app.UIAxesXShifts.Box = 'on';
            xlabel(app.UIAxesXShifts, 'Wavelength (nm)')
            ylabel(app.UIAxesXShifts, 'X Shift (nm)')

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)
        % Construct app
        function app = SpectralCalibration

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)
            
            addpath(fullfile(pwd,'lib'));
            addpath(fullfile(pwd,'lib/dwp_scripts'));
            addpath(fullfile(pwd,'lib/bioformats_tools'));

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end

    % Event handling
    events
        CalibrationFileSaved  % Event sent when the calibration file is saved
    end
end