classdef RainbowSTORM < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure %
        MainGridLayout                  matlab.ui.container.GridLayout %

        PreliminariesPanel              matlab.ui.container.Panel %
            PreliminariesGridLayout         matlab.ui.container.GridLayout %
            ThreeDProcessingButton          matlab.ui.control.StateButton %
            BatchModeButton                 matlab.ui.control.StateButton %
            SpecCaliButton                  matlab.ui.control.Button %
            AxialCaliButton                 matlab.ui.control.Button %

        DirectoriesPanel                matlab.ui.container.Panel
            DirectoriesGridLayout           matlab.ui.container.GridLayout %

            Order0CroppingRegionButton      matlab.ui.control.Button %
            Order0InputTextArea             matlab.ui.control.TextArea %
            Order0InputTextAreaLabel        matlab.ui.control.Label %
            Order0BrowseButton              matlab.ui.control.Button %

            Order1CroppingRegionButton      matlab.ui.control.Button %
            Order1InputTextArea             matlab.ui.control.TextArea %
            Order1InputTextAreaLabel        matlab.ui.control.Label %
            Order1BrowseButton              matlab.ui.control.Button %

            SpecCaliFileTextArea            matlab.ui.control.TextArea %
            SpecCaliFileTextAreaLabel       matlab.ui.control.Label %
            SpecCaliBrowseButton            matlab.ui.control.Button %

            AxialCaliFileTextArea           matlab.ui.control.TextArea %
            AxialCaliFileTextAreaLabel      matlab.ui.control.Label % 
            AxialCaliBrowseButton           matlab.ui.control.Button %

            OutputFolderTextArea            matlab.ui.control.TextArea %
            OutputFolderTextAreaLabel       matlab.ui.control.Label %
            OutputBrowseButton              matlab.ui.control.Button %

        SettingsPanel                   matlab.ui.container.Panel %
            SettingsGridLayout              matlab.ui.container.GridLayout %
            nmEditFieldLabel                matlab.ui.control.Label %
            nmEditField                     matlab.ui.control.NumericEditField %
            ShowVisualizationCheckBox       matlab.ui.control.CheckBox %
            PlotHistogramsCheckBox          matlab.ui.control.CheckBox %
            CentralWavelengthSlider         matlab.ui.control.Slider %
            CentralWavelengthSliderLabel    matlab.ui.control.Label %

        StatusLabel                     matlab.ui.control.Label     %
        RunButton                       matlab.ui.control.Button    %
    end

    
    properties (Access = private)
        dir_input0path % path to the 0th order input directory/files
        dir_input1path % path to the 1st order input directory/files
        dir_speccali % path to the spectral calibration file
        dir_axialcali = '';  % path to the axial calibration file
        dir_outputpath % path to the output directory

        order0_crops = zeros(1,4);  % cropping parameters for the 0th order
        order1_crops = zeros(1,4);  % cropping parameters for the 1st order

        processing_central_wavelength = nan; % central wavelength for processing
        processing_cancelled = false; 
        processing_complete = false;

        order0_crops_set = false; 
        order1_crops_set = false;

        enable_settings_panel = false;
        enable_output_panel = false;
        enable_run_button = false;

        table_output
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        %% Callbacks for elements in the PreliminariesPanel
        % Value changed function: ThreeDProcessingButton
        function ThreeDProcessingButtonValueChanged(app, ~)
            if app.ThreeDProcessingButton.Value
                update_value = 'on';
            else
                update_value = 'off';
            end

            app.AxialCaliButton.Enable = update_value;
            app.AxialCaliBrowseButton.Enable = update_value;
            app.AxialCaliFileTextArea.Enable = update_value;
            app.AxialCaliFileTextAreaLabel.Enable = update_value;
            CheckInputsAndUpdate(app);
        end

        % Value changed function: BatchModeButton
        function BatchModeButtonValueChanged(app, ~)
            if app.BatchModeButton.Value
                app.Order0InputTextAreaLabel.Text = '0th Order Input Folder/File(s)';
                app.Order1InputTextAreaLabel.Text = '1st Order Input Folder/File(s)';
                app.OutputFolderTextAreaLabel.Text = 'Output Folder';
                app.enable_settings_panel = false;
                UpdateSwitchablePanels(app);
                app.StatusLabel.Text = 'Batch mode is not implemented yet.';
            else
                app.Order0InputTextAreaLabel.Text = '0th Order Input File';
                app.Order1InputTextAreaLabel.Text = '1st Order Input File';
                app.OutputFolderTextAreaLabel.Text = 'Output File';
                CheckInputsAndUpdate(app);
            end
        end

        % Button pushed function: SpecCaliButton
        function SpecCaliButtonPushed(app, ~)
            % on button press, run the spectral calibration gui
            speccali_gui = SpectralCalibration();

            % set the window style to modal so that the user
            % cannot interact with the main gui while the calibration
            % gui is open
            speccali_gui.UIFigure.WindowStyle = 'modal';
            
            % add a listener event to the gui to know when the
            % calibration file is saved
            addlistener(speccali_gui, 'CalibrationFileSaved', @(src, event) updateDirSpeccali(app, event));
        end

        % Update the spectral calibration directory
        function updateDirSpeccali(app, event)
            % update the directory of the spectral calibration file
            app.dir_speccali = event.filename;
            app.SpecCaliFileTextArea.Value = app.dir_speccali;
            CheckInputsAndUpdate(app);
        end

        % Button pushed function: AxialCaliButton
        function AxialCaliButtonPushed(app, ~)
            % on button press, run the axial calibration gui
            if isMATLABReleaseOlderThan('R2023b')
                axialcali_gui = AxialCalibrationLegacy();
            else
                axialcali_gui = AxialCalibration();
            end

            % set the window style to modal so that the user
            % cannot interact with the main gui while the calibration
            % gui is open
            axialcali_gui.UIFigure.WindowStyle = 'modal';
            
            % add a listener event to the gui to know when the
            % calibration file is saved
            addlistener(axialcali_gui, 'CalibrationFileSaved', @(src, event) updateDirAxialcali(app, event));
        end

        % Update the axial calibration directory
        function updateDirAxialcali(app, event)
            % update the directory of the axial calibration file
            app.dir_axialcali = event.filename;
            app.AxialCaliFileTextArea.Value = app.dir_axialcali;
            app.CheckInputs(app);
        end


        %% Callbacks for elements in the DirectoriesPanel
        % Button pushed function: Order0CroppingRegionButton
        function Order0CroppingRegionButtonPushed(app, ~)
            % on button press, run the cropping region gui
            roi_gui = RoiSelector();
            % wait for the gui to be created
            while(strcmpi(roi_gui.UIFigure.Visible, 'off'))
                pause(0.1);
            end
            roi_gui.UIFigure.WindowStyle = 'modal';
            roi_gui.xEditField.Value = app.order0_crops(1);
            roi_gui.yEditField.Value = app.order0_crops(2);
            roi_gui.wEditField.Value = app.order0_crops(3);
            roi_gui.hEditField.Value = app.order0_crops(4);

            addlistener(roi_gui, 'SetCrops', @(src, event) updateOrder0Crops(app, event));
        end

        % Update the cropping parameters for the 0th order
        function updateOrder0Crops(app, event)
            if app.order0_crops_set == false && isequal(app.order0_crops, event.crops)
                return;
            end
            app.order0_crops_set = true;
            app.order0_crops = event.crops;
        end

        % Button pushed function: Order0BrowseButton
        function Order0BrowseButtonPushed(app, ~)
            input_dir = uigetdirfile(pwd);
            if ~isempty(input_dir)
                app.dir_input0path = input_dir;
                app.Order0InputTextArea.Value = app.dir_input0path;
            end

            figure(app.UIFigure); % bring the app to the front
            CheckInputsAndUpdate(app);
        end

        % Button pushed function: Order1CroppingRegionButton
        function Order1CroppingRegionButtonPushed(app, ~)
            % on button press, run the cropping region gui
            roi_gui = RoiSelector();
            % wait for the gui to be created
            while(strcmpi(roi_gui.UIFigure.Visible, 'off'))
                pause(0.1);
            end
            roi_gui.UIFigure.WindowStyle = 'modal';
            roi_gui.xEditField.Value = app.order1_crops(1);
            roi_gui.yEditField.Value = app.order1_crops(2);
            roi_gui.wEditField.Value = app.order1_crops(3);
            roi_gui.hEditField.Value = app.order1_crops(4);

            addlistener(roi_gui, 'SetCrops', @(src, event) updateOrder1Crops(app, event));
        end

        % Update the cropping parameters for the 1st order
        function updateOrder1Crops(app, event)
            if app.order1_crops_set == false && isequal(app.order1_crops, event.crops)
                return;
            end
            app.order1_crops_set = true;
            app.order1_crops = event.crops;
        end

        % Button pushed function: Order1BrowseButton
        function Order1BrowseButtonPushed(app, ~)
            input_dir = uigetdirfile(pwd);
            if ~isempty(input_dir)
                app.dir_input1path = input_dir;
                app.Order1InputTextArea.Value = app.dir_input1path;
            end
            figure(app.UIFigure); % bring the app to the front
            CheckInputsAndUpdate(app);
        end

        % Button pushed function: BrowseSpecCaliButton
        function SpecCaliBrowseButtonPushed(app, ~)
            [file, path] = uigetfile('*.mat');
            if file ~= 0 
                app.dir_speccali = fullfile(path, file);
                app.SpecCaliFileTextArea.Value = app.dir_speccali;
            end
            figure(app.UIFigure); % bring the app to the front
            CheckInputsAndUpdate(app);
        end

        % Button pushed function: BrowseAxialCaliButton
        function AxialCaliBrowseButtonPushed(app, ~)
            [file, path] = uigetfile('*.mat');
            if file ~= 0
                app.dir_axialcali = fullfile(path, file);
                app.AxialCaliFileTextArea.Value = app.dir_axialcali;
            end
            figure(app.UIFigure); % bring the app to the front
            CheckInputsAndUpdate(app);
        end

        % Button pushed function: BrowseOutputButton
        function OutputBrowseButtonPushed(app, ~)
            if app.BatchModeButton.Value
                output_dir = uigetdir();
            else
                [file, path] = uiputfile({'*.csv', 'CSV (Comma Delimited)'}, 'Save as');
                output_dir = fullfile(path, file);
            end
            % error handling for cancel
            if output_dir ~= 0
                app.dir_outputpath = output_dir;
                app.OutputFolderTextArea.Value = app.dir_outputpath;
            end
            figure(app.UIFigure); % bring the app to the front
            CheckInputsAndUpdate(app);
        end

        
        %% Callbacks for elements in the DirectoriesPanel
        % If the central wavelength slider is changing
        function CentralWavelengthSliderValueChanging(app, ~)
            app.processing_central_wavelength = app.CentralWavelengthSlider.Value;
            app.nmEditField.Value = app.processing_central_wavelength;
        end

        function CheckInputsAndUpdate(app, ~)
            app.enable_output_panel = false;
            app.enable_settings_panel = false;
            CheckInputs(app);
            UpdateSwitchablePanels(app);
        end

        function CheckInputs(app, ~)
            % check if all the necessary fields are filled
            if isempty(app.dir_input0path)
                app.StatusLabel.Text = 'Please select input files and calibration file(s).';
                app.StatusLabel.FontColor = 'black';
                return;
            end
            if isempty(app.dir_input1path)
                app.StatusLabel.Text = 'Please select input files and calibration file(s).';
                app.StatusLabel.FontColor = 'black';
                return;
            end

            % check that the input0 and input1 are of the same type
            if isfolder(app.dir_input0path) && ~isfolder(app.dir_input1path)
                app.StatusLabel.Text = 'The type of input for the 0th order and the 1st order is not the same';
                app.StatusLabel.FontColor = 'black';
                return;
            end

            if isempty(app.dir_speccali)
                app.StatusLabel.Text = 'Please select calibration file(s).';
                app.StatusLabel.FontColor = 'black';
                return;
            end

            file_contents = whos('-file', app.dir_speccali);
            if ~any(strcmp({file_contents.name}, 'speccali'))
                app.StatusLabel.Text = 'The spectral calibration file is not valid.';
                app.StatusLabel.FontColor = 'red';
                errordlg('The spectral calibration file is not valid.');
                return;
            end

            if app.ThreeDProcessingButton.Value
                if isempty(app.dir_axialcali)
                    return;
                end
                file_contents = whos('-file', app.dir_axialcali);
                if ~any(strcmp({file_contents.name}, 'zcali'))
                    app.StatusLabel.Text = 'The axial calibration file is not valid.';
                    app.StatusLabel.FontColor = 'red';
                    errordlg('The axial calibration file is not valid.');
                    return;
                end
            end
            app.enable_output_panel = true;

            if isempty(app.dir_outputpath)
                app.StatusLabel.Text = 'Please select output file(s).';
                app.StatusLabel.FontColor = 'black';
                return;
            end

            % if app.order0_crops_set && app.order1_crops_set
            %     app.enable_settings_panel = true;
            % elseif ~(~app.order0_crops_set && ~app.order1_crops_set)
            %     app.StatusLabel.Text = 'Please set the cropping regions for both orders.';
            %     app.StatusLabel.FontColor = 'black';
            %     return;
            % end

            app.enable_run_button = true;
            app.StatusLabel.Text = 'Ready to run.';
            app.StatusLabel.FontColor = 'black';
        end

        function UpdateSwitchablePanels(app, ~)
            % Update output panel
            if app.enable_output_panel
                update_value = 'on';
            else
                update_value = 'off';
            end
            app.OutputFolderTextArea.Enable = update_value;
            app.OutputFolderTextAreaLabel.Enable = update_value;
            app.OutputBrowseButton.Enable = update_value;

            % Update settings panel
            if app.enable_settings_panel && app.enable_output_panel
                update_value = 'on';
            else
                update_value = 'off';
            end
            app.nmEditField.Enable = update_value;
            app.nmEditFieldLabel.Enable = update_value;
            app.CentralWavelengthSlider.Enable = update_value;
            app.CentralWavelengthSliderLabel.Enable = update_value;
            app.PlotHistogramsCheckBox.Enable = update_value;
            app.ShowVisualizationCheckBox.Enable = update_value;

            if app.enable_output_panel && app.enable_run_button
                update_value = 'on';
            else
                update_value = 'off';
            end
            app.RunButton.Enable = update_value;
        end

        % If the edit field is changed
        function nmEditFieldValueChanged(app, ~)
            % Check if the value is within the limits
            if app.nmEditField.Value < 500
                app.nmEditField.Value = 500;
            elseif app.nmEditField.Value > 800
                app.nmEditField.Value = 800;
            end
            app.processing_central_wavelength = app.nmEditField.Value;
            app.CentralWavelengthSlider.Value = app.processing_central_wavelength;
        end

        % If the run button is pushed
        function RunButtonPushed(app, ~)
            if app.processing_cancelled == false && app.processing_complete == false
                % disable all the other buttons and menus
                app.OutputFolderTextArea.Enable = 'off';
                app.OutputFolderTextAreaLabel.Enable = 'off';
                app.OutputBrowseButton.Enable = 'off';
                app.nmEditField.Enable = 'off';
                app.nmEditFieldLabel.Enable = 'off';
                app.CentralWavelengthSlider.Enable = 'off';
                app.CentralWavelengthSliderLabel.Enable = 'off';
                app.PlotHistogramsCheckBox.Enable = 'off';
                app.ShowVisualizationCheckBox.Enable = 'off';
                app.ThreeDProcessingButton.Enable = 'off';
                app.BatchModeButton.Enable = 'off';
                app.SpecCaliButton.Enable = 'off';
                app.AxialCaliButton.Enable = 'off';
                app.Order0CroppingRegionButton.Enable = 'off';
                app.Order0InputTextArea.Enable = 'off';
                app.Order0BrowseButton.Enable = 'off';
                app.Order1CroppingRegionButton.Enable = 'off';
                app.Order1InputTextArea.Enable = 'off';
                app.Order1BrowseButton.Enable = 'off';
                app.SpecCaliFileTextArea.Enable = 'off';
                app.SpecCaliFileTextAreaLabel.Enable = 'off';
                app.SpecCaliBrowseButton.Enable = 'off';
                app.AxialCaliFileTextArea.Enable = 'off';
                app.AxialCaliFileTextAreaLabel.Enable = 'off';
                app.AxialCaliBrowseButton.Enable = 'off';

                % start the processing
                app.processing_cancelled = false;
                app.processing_complete = false;
                app.RunButton.Text = 'Cancel';
                app.processfile_core();

                % when the processing is complete, change the button to display 'View Output'
                app.RunButton.Text = 'View Output';

            elseif app.processing_cancelled == false && app.processing_complete == true
                % if the processing is completed and the button is pressed, we view the output
                % open the image_viewer gui
                ImageViewer(app.table_output);

            elseif app.processing_cancelled == true && app.processing_complete == false
                % if the processing is cancelled, change the button to display 'Run'
                app.processing_cancelled = false;
                app.RunButton.Text = 'Run';
                app.StatusLabel.Text = 'Processing cancelled. Press Run to start again.';
            end
        end

        function processfile_core(app, ~)
            % run the processing function
            app.StatusLabel.Text = 'Reading input files...';
            drawnow;
            ts_table0 = readtable(app.dir_input0path, 'preservevariablenames', true);
            ts_table1 = readtable(app.dir_input1path, 'preservevariablenames', true);

            if app.processing_cancelled
                app.StatusLabel.Text = 'Processing cancelled.';
                return;
            end

            app.StatusLabel.Text = 'Reading calibration files...';
            drawnow;
            loaded_speccali = load(app.dir_speccali, 'speccali');
            loaded_speccali = loaded_speccali.speccali;

            [~, idx] = min(abs(loaded_speccali.wavelengths - app.CentralWavelengthSlider.Value));

            img_pxsz = 110;

            if app.order0_crops_set && app.order1_crops_set
                mid_x0 = (app.order0_crops(1) + (app.order0_crops(3)) / 2) * img_pxsz;
                mid_y0 = (app.order0_crops(2) + (app.order0_crops(4)) / 2) * img_pxsz;
                xoff = (app.order1_crops(1) - app.order0_crops(1)) * img_pxsz;
            else
                mid_x0 = (min(ts_table0{:, 'x [nm]'}) + max(ts_table0{:, 'x [nm]'})) / 2;
                mid_y0 = (min(ts_table0{:, 'y [nm]'}) + max(ts_table0{:, 'y [nm]'})) / 2;
                xoff = 0;
            end

            ts_table0{:, 'x [nm]'} = (ts_table0{:, 'x [nm]'} - mid_x0) .* loaded_speccali.xscale(idx) + mid_x0;
            ts_table0{:, 'y [nm]'} = (ts_table0{:, 'y [nm]'} - mid_y0) .* loaded_speccali.yscale(idx) + mid_y0;

            % correct the x and y values of the 1st order (to be deprecated)
            app.StatusLabel.Text = 'Matching 0th and 1st order...';
            drawnow;

            [xcomp, ycomp] = corr_xy(app, ts_table0, ts_table1);

            if app.processing_cancelled
                app.StatusLabel.Text = 'Processing cancelled.';
                return;
            end

            % correct the x1 and y1 values with tform_mean and fx at the central wavelength, yshift_mean
            ts_table1{:, 'x [nm]'} = ts_table1{:, 'x [nm]'} + xcomp;
            ts_table1{:, 'y [nm]'} = ts_table1{:, 'y [nm]'} + ycomp;

            % sort the tables by frame
            ts_table0 = sortrows(ts_table0, 'frame');
            ts_table1 = sortrows(ts_table1, 'frame');

            app.StatusLabel.Text = 'Matching 0th and 1st order localizations...';
            drawnow;
            [matched_idx0, matched_idx1] = match_localizations(app, ts_table0, ts_table1);

            if app.processing_cancelled
                app.StatusLabel.Text = 'Processing cancelled.';
                return;
            end

            % filter the localizations by the matched indices
            tsnew_table0 = ts_table0(ismember(ts_table0{:, 'id'}, matched_idx0), :);
            tsnew_table1 = ts_table1(ismember(ts_table1{:, 'id'}, matched_idx1), :);

            % filter the localizations where abs(y_1 - y_0) < 450 and abs(x_1 - x_0) < 2200
            sel = (abs(tsnew_table1{:, 'y [nm]'} - tsnew_table0{:, 'y [nm]'}) < 450) & ...
                (abs(tsnew_table1{:, 'x [nm]'} - tsnew_table0{:, 'x [nm]'}) < 2200);

            tsnew_table0 = tsnew_table0(sel, :);
            tsnew_table1 = tsnew_table1(sel, :);

            app.StatusLabel.Text = 'Generating output...';
            drawnow;
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

            ts_output{:, 'id'} = (1:length(tsnew_table0{:, 'frame'}))';
            ts_output{:, 'frame'} = tsnew_table0{:, 'frame'};

            ts_output{:, 'x [nm]'} = tsnew_table0{:, 'x [nm]'};
            ts_output{:, 'y [nm]'} = tsnew_table0{:, 'y [nm]'};

            if app.ThreeDProcessingButton.Value
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

                ts_output{:, 'z [nm]'} = getz(app, temp_sigma0, temp_sigma1);

            else
                ts_output{:, 'z [nm]'} = nan(length(tsnew_table0{:, 'frame'}), 1);
            end

            ts_output{:, 'centroid [nm]'} = dwp_px2wl( ...
                (tsnew_table1{:, 'x [nm]'} - xcomp + xoff) - ...
                (tsnew_table0{:, 'x [nm]'}), loaded_speccali.fx);

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
            
            app.table_output = ts_output;

            % Write the output to a csv file
            app.StatusLabel.Text = 'Writing output to file...';
            drawnow;
            writetable(ts_output, app.dir_outputpath);

            app.StatusLabel.Text = 'Processing complete.';
            app.processing_complete = true;
        end

        function [matched_idx0, matched_idx1] = match_localizations(~, ts_table0, ts_table1)
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

        function [xcomp, ycomp] = corr_xy(~, ts_table0, ts_table1)
            % check if ts_table0 and ts_table1 are tables, otherwise convert them
            if istable(ts_table0) == 0 && ischar(ts_table0) == 1
                ts_table0 = readtable(ts_table0, ...
                    'preservevariablenames', true);
            end
            if istable(ts_table1) == 0 && ischar(ts_table1) == 1
                ts_table1 = readtable(ts_table1, ...
                    'preservevariablenames', true);
            end
            
            % get the maximum values of ts_table0 and ts_table1
            max_x0 = max(ts_table0{:, 'x [nm]'});
            max_y0 = max(ts_table0{:, 'y [nm]'});
            max_x1 = max(ts_table1{:, 'x [nm]'});
            max_y1 = max(ts_table1{:, 'y [nm]'});

            sample_px = round(max([max_x0, max_x1, max_y0, max_y1]) ./ 1024, -1);
            
            % sort the tables by frame
            ts_table0 = sortrows(ts_table0, 'frame');
            ts_table1 = sortrows(ts_table1, 'frame');

            x0 = ts_table0{:, 'x [nm]'};
            y0 = ts_table0{:, 'y [nm]'};
            x1 = ts_table1{:, 'x [nm]'};
            y1 = ts_table1{:, 'y [nm]'};
            
            im0 = histcounts2(x0, y0, 'binwidth', [sample_px, sample_px], 'xbinlimits', [0, max(max_x0,max_x1)], 'ybinlimits', [0, max(max_y0,max_y1)])';
            im1 = histcounts2(x1, y1, 'binwidth', [sample_px, sample_px], 'xbinlimits', [0, max(max_x0,max_x1)], 'ybinlimits', [0, max(max_y0,max_y1)])';

            im0 = imgaussfilt(im0, 2);
            im1 = imgaussfilt(im1, 2);
            
            % perform cross correlation on the images
            corr_im = normxcorr2(im0, im1);
            
            % perform a low pass filter on the cross correlation image
            corr_im = imgaussfilt(corr_im, 5);

            % figure(2);
            % subplot(1,3,1);
            % imshow(im0,[]);
            % subplot(1,3,2);
            % imshow(im1,[]);
            % subplot(1,3,3);
            % imshow(corr_im,[]);
            
            [ypeak, xpeak] = find(corr_im == max(corr_im(:)));
            xcomp = -(xpeak-size(im0,2))*sample_px;
            ycomp = -(ypeak-size(im0,1))*sample_px;
        end

        function z = getz(app, sigma0, sigma1)
            % load the zcali file
            loaded_zcali = load(app.dir_axialcali, 'zcali');
            % the zcali file contains the following variables:
            % sigma0_fitted, sigma1_fitted, z_values

            sigma0_fitted = loaded_zcali.zcali.sigma0_fitted;
            sigma1_fitted = loaded_zcali.zcali.sigma1_fitted;
            z_values = loaded_zcali.zcali.z_values;

            % calculate the z values for a given sigma0 and sigma1
            z = interp1(axialf(app, sigma0_fitted, sigma1_fitted), z_values, axialf(app, sigma0, sigma1), 'pchip');
        end
            
        function F = axialf(~,wn,wp)
            F = (wp.*wp-wn.*wn)./(wp.*wp+wn.*wn);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 600 500];
            app.UIFigure.Name = 'RainbowSTORM v1.5';

            % Create MainGridLayout
            app.MainGridLayout = uigridlayout(app.UIFigure);
            app.MainGridLayout.ColumnWidth = {5, '1x', 10, 100, 5};
            app.MainGridLayout.RowHeight = {55, '1x', 70, 3, 30, 3};
            app.MainGridLayout.ColumnSpacing = 0;
            app.MainGridLayout.RowSpacing = 0;
            app.MainGridLayout.Padding = [0 0 0 0];


            % Create PreliminariesPanel
            app.PreliminariesPanel = uipanel(app.MainGridLayout);
            app.PreliminariesPanel.BorderType = 'none';
            app.PreliminariesPanel.Title = 'Preliminaries';
            app.PreliminariesPanel.Layout.Row = 1;
            app.PreliminariesPanel.Layout.Column = [1 5];
            app.PreliminariesPanel.FontWeight = 'bold';

            % Create PreliminariesGridLayout
            app.PreliminariesGridLayout = uigridlayout(app.PreliminariesPanel);
            app.PreliminariesGridLayout.ColumnWidth = {120, 120, '1x', 120, 120};
            app.PreliminariesGridLayout.RowHeight = {'1x'};
            app.PreliminariesGridLayout.Padding = [5 3 5 3];

            % Create ThreeDProcessingButton
            app.ThreeDProcessingButton = uibutton(app.PreliminariesGridLayout, 'state');
            app.ThreeDProcessingButton.Text = '3D Processing';
            app.ThreeDProcessingButton.Layout.Row = 1;
            app.ThreeDProcessingButton.Layout.Column = 1;
            app.ThreeDProcessingButton.ValueChangedFcn = createCallbackFcn(app, @ThreeDProcessingButtonValueChanged, true);

            % Create BatchModeButton
            app.BatchModeButton = uibutton(app.PreliminariesGridLayout, 'state');
            app.BatchModeButton.Enable = 'off';
            app.BatchModeButton.Visible = 'off';
            app.BatchModeButton.Text = 'Batch Mode';
            app.BatchModeButton.Layout.Row = 1;
            app.BatchModeButton.Layout.Column = 2;
            app.BatchModeButton.ValueChangedFcn = createCallbackFcn(app, @BatchModeButtonValueChanged, true);

            % Create SpecCaliButton
            app.SpecCaliButton = uibutton(app.PreliminariesGridLayout, 'push');
            app.SpecCaliButton.Layout.Row = 1;
            app.SpecCaliButton.Layout.Column = 4;
            app.SpecCaliButton.Text = 'Spectral Calibration';
            app.SpecCaliButton.ButtonPushedFcn = createCallbackFcn(app, @SpecCaliButtonPushed, true);

            % Create AxialCaliButton
            app.AxialCaliButton = uibutton(app.PreliminariesGridLayout, 'push');
            app.AxialCaliButton.Enable = 'off';
            app.AxialCaliButton.Layout.Row = 1;
            app.AxialCaliButton.Layout.Column = 5;
            app.AxialCaliButton.Text = 'Axial Calibration';
            app.AxialCaliButton.ButtonPushedFcn = createCallbackFcn(app, @AxialCaliButtonPushed, true);


            % Create DirectoriesPanel
            app.DirectoriesPanel = uipanel(app.MainGridLayout);
            app.DirectoriesPanel.BorderType = 'none';
            app.DirectoriesPanel.Title = 'Directories';
            app.DirectoriesPanel.Layout.Row = 2;
            app.DirectoriesPanel.Layout.Column = [1 5];
            app.DirectoriesPanel.FontWeight = 'bold';

            % Create DirectoriesGridLayout
            app.DirectoriesGridLayout = uigridlayout(app.DirectoriesPanel);
            app.DirectoriesGridLayout.ColumnWidth = {160, '1x', 100};
            app.DirectoriesGridLayout.RowHeight = {25, 25, '1x', 5, 25, 25, '1x', 5, 25, '1x', 5, 25, '1x', 5, 25, 25, '1x'};
            app.DirectoriesGridLayout.RowSpacing = 2;
            app.DirectoriesGridLayout.Padding = [5 5 5 5];

            % Create Order0CroppingRegionButton
            app.Order0CroppingRegionButton = uibutton(app.DirectoriesGridLayout, 'push');
            app.Order0CroppingRegionButton.Layout.Row = 2;
            app.Order0CroppingRegionButton.Layout.Column = 1;
            app.Order0CroppingRegionButton.Text = 'Cropping Region';
            app.Order0CroppingRegionButton.ButtonPushedFcn = createCallbackFcn(app, @Order0CroppingRegionButtonPushed, true);

            % Create Order0InputTextArea
            app.Order0InputTextArea = uitextarea(app.DirectoriesGridLayout);
            app.Order0InputTextArea.Layout.Row = [1 3];
            app.Order0InputTextArea.Layout.Column = 2;
            app.Order0InputTextArea.Editable = 'off';

            % Create Order0InputTextAreaLabel
            app.Order0InputTextAreaLabel = uilabel(app.DirectoriesGridLayout);
            app.Order0InputTextAreaLabel.Layout.Row = 1;
            app.Order0InputTextAreaLabel.Layout.Column = 1;
            app.Order0InputTextAreaLabel.Text = '0th Order Input File';

            % Create Order0BrowseButton
            app.Order0BrowseButton = uibutton(app.DirectoriesGridLayout, 'push');
            app.Order0BrowseButton.Layout.Row = 1;
            app.Order0BrowseButton.Layout.Column = 3;
            app.Order0BrowseButton.Text = 'Browse';
            app.Order0BrowseButton.ButtonPushedFcn = createCallbackFcn(app, @Order0BrowseButtonPushed, true);


            % Create Order1CroppingRegionButton
            app.Order1CroppingRegionButton = uibutton(app.DirectoriesGridLayout, 'push');
            app.Order1CroppingRegionButton.Layout.Row = 6;
            app.Order1CroppingRegionButton.Layout.Column = 1;
            app.Order1CroppingRegionButton.Text = 'Cropping Region';
            app.Order1CroppingRegionButton.ButtonPushedFcn = createCallbackFcn(app, @Order1CroppingRegionButtonPushed, true);

            % Create Order1InputTextArea
            app.Order1InputTextArea = uitextarea(app.DirectoriesGridLayout);
            app.Order1InputTextArea.Editable = 'off';
            app.Order1InputTextArea.Layout.Row = [5 7];
            app.Order1InputTextArea.Layout.Column = 2;

            % Create Order1InputTextAreaLabel
            app.Order1InputTextAreaLabel = uilabel(app.DirectoriesGridLayout);
            app.Order1InputTextAreaLabel.Layout.Row = 5;
            app.Order1InputTextAreaLabel.Layout.Column = 1;
            app.Order1InputTextAreaLabel.Text = '1st Order Input File';

            % Create Order1BrowseButton
            app.Order1BrowseButton = uibutton(app.DirectoriesGridLayout, 'push');
            app.Order1BrowseButton.Layout.Row = 5;
            app.Order1BrowseButton.Layout.Column = 3;
            app.Order1BrowseButton.Text = 'Browse';
            app.Order1BrowseButton.ButtonPushedFcn = createCallbackFcn(app, @Order1BrowseButtonPushed, true);


            % Create SpecCaliFileTextArea
            app.SpecCaliFileTextArea = uitextarea(app.DirectoriesGridLayout);
            app.SpecCaliFileTextArea.Editable = 'off';
            app.SpecCaliFileTextArea.Layout.Row = [9 10];
            app.SpecCaliFileTextArea.Layout.Column = 2;

            % Create SpecCaliFileTextAreaLabel
            app.SpecCaliFileTextAreaLabel = uilabel(app.DirectoriesGridLayout);
            app.SpecCaliFileTextAreaLabel.Layout.Row = 9;
            app.SpecCaliFileTextAreaLabel.Layout.Column = 1;
            app.SpecCaliFileTextAreaLabel.Text = 'Spectral Calibration File';

            % Create BrowseSpecCaliButton
            app.SpecCaliBrowseButton = uibutton(app.DirectoriesGridLayout, 'push');
            app.SpecCaliBrowseButton.Layout.Row = 9;
            app.SpecCaliBrowseButton.Layout.Column = 3;
            app.SpecCaliBrowseButton.Text = 'Browse';
            app.SpecCaliBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @SpecCaliBrowseButtonPushed, true);


            % Create AxialCaliFileTextArea
            app.AxialCaliFileTextArea = uitextarea(app.DirectoriesGridLayout);
            app.AxialCaliFileTextArea.Editable = 'off';
            app.AxialCaliFileTextArea.Enable = 'off';
            app.AxialCaliFileTextArea.Layout.Row = [12 13];
            app.AxialCaliFileTextArea.Layout.Column = 2;

            % Create AxialCaliFileTextAreaLabel
            app.AxialCaliFileTextAreaLabel = uilabel(app.DirectoriesGridLayout);
            app.AxialCaliFileTextAreaLabel.Enable = 'off';
            app.AxialCaliFileTextAreaLabel.Layout.Row = 12;
            app.AxialCaliFileTextAreaLabel.Layout.Column = 1;
            app.AxialCaliFileTextAreaLabel.Text = 'Axial Calibration File';

            % Create AxialCaliBrowseButton
            app.AxialCaliBrowseButton = uibutton(app.DirectoriesGridLayout, 'push');
            app.AxialCaliBrowseButton.Enable = 'off';
            app.AxialCaliBrowseButton.Layout.Row = 12;
            app.AxialCaliBrowseButton.Layout.Column = 3;
            app.AxialCaliBrowseButton.Text = 'Browse';
            app.AxialCaliBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @AxialCaliBrowseButtonPushed, true);


            % Create OutputFolderTextArea
            app.OutputFolderTextArea = uitextarea(app.DirectoriesGridLayout);
            app.OutputFolderTextArea.Layout.Row = [15 17];
            app.OutputFolderTextArea.Layout.Column = 2;
            app.OutputFolderTextArea.Editable = 'off';
            app.OutputFolderTextArea.Enable = 'off';

            % Create OutputFolderTextAreaLabel
            app.OutputFolderTextAreaLabel = uilabel(app.DirectoriesGridLayout);
            app.OutputFolderTextAreaLabel.Layout.Row = 15;
            app.OutputFolderTextAreaLabel.Layout.Column = 1;
            app.OutputFolderTextAreaLabel.Text = 'Output File';
            app.OutputFolderTextAreaLabel.Enable = 'off';

            % Create OutputBrowseButton
            app.OutputBrowseButton = uibutton(app.DirectoriesGridLayout, 'push');
            app.OutputBrowseButton.Layout.Row = 15;
            app.OutputBrowseButton.Layout.Column = 3;
            app.OutputBrowseButton.Text = 'Browse';
            app.OutputBrowseButton.Enable = 'off';
            app.OutputBrowseButton.ButtonPushedFcn = createCallbackFcn(app, @OutputBrowseButtonPushed, true);


            % Create SettingsPanel
            app.SettingsPanel = uipanel(app.MainGridLayout);
            app.SettingsPanel.BorderType = 'none';
            app.SettingsPanel.Title = 'Settings';
            app.SettingsPanel.Layout.Row = 3;
            app.SettingsPanel.Layout.Column = [1 5];
            app.SettingsPanel.FontWeight = 'bold';

            % Create SettingsGridLayout
            app.SettingsGridLayout = uigridlayout(app.SettingsPanel);
            app.SettingsGridLayout.ColumnWidth = {60, 60, '1x', 10, 140};
            app.SettingsGridLayout.ColumnSpacing = 2;
            app.SettingsGridLayout.RowSpacing = 2;
            app.SettingsGridLayout.Padding = [5 3 5 3];

            % Create nmEditFieldLabel
            app.nmEditFieldLabel = uilabel(app.SettingsGridLayout);
            app.nmEditFieldLabel.Enable = 'off';
            app.nmEditFieldLabel.Layout.Row = 2;
            app.nmEditFieldLabel.Layout.Column = 2;
            app.nmEditFieldLabel.Text = 'nm';
            
            % Create nmEditField
            app.nmEditField = uieditfield(app.SettingsGridLayout, 'numeric');
            app.nmEditField.Limits = [500 800];
            app.nmEditField.Layout.Row = 2;
            app.nmEditField.Layout.Column = 1;
            app.nmEditField.Value = 700;
            app.nmEditField.Enable = 'off';
            app.nmEditField.ValueChangedFcn = createCallbackFcn(app, @nmEditFieldValueChanged, true);

            % Create ShowVisualizationCheckBox
            app.ShowVisualizationCheckBox = uicheckbox(app.SettingsGridLayout);
            app.ShowVisualizationCheckBox.Text = 'Show Visualization';
            app.ShowVisualizationCheckBox.Layout.Row = 2;
            app.ShowVisualizationCheckBox.Layout.Column = 5;
            app.ShowVisualizationCheckBox.Value = true;
            app.ShowVisualizationCheckBox.Enable = 'off';

            % Create PlotHistogramsCheckBox
            app.PlotHistogramsCheckBox = uicheckbox(app.SettingsGridLayout);
            app.PlotHistogramsCheckBox.Text = 'Plot Histograms';
            app.PlotHistogramsCheckBox.Layout.Row = 1;
            app.PlotHistogramsCheckBox.Layout.Column = 5;
            app.PlotHistogramsCheckBox.Value = true;
            app.PlotHistogramsCheckBox.Enable = 'off';

            % Create CentralWavelengthSlider
            app.CentralWavelengthSlider = uislider(app.SettingsGridLayout);
            app.CentralWavelengthSlider.Limits = [500 800];
            app.CentralWavelengthSlider.MajorTicks = 500:100:800;
            app.CentralWavelengthSlider.MinorTicks = 500:10:800;
            app.CentralWavelengthSlider.Layout.Row = 1;
            app.CentralWavelengthSlider.Layout.Column = 3;
            app.CentralWavelengthSlider.Value = 700;
            app.CentralWavelengthSlider.Enable = 'off';
            app.CentralWavelengthSlider.ValueChangingFcn = createCallbackFcn(app, @CentralWavelengthSliderValueChanging, true);

            % Create CentralWavelengthSliderLabel
            app.CentralWavelengthSliderLabel = uilabel(app.SettingsGridLayout);
            app.CentralWavelengthSliderLabel.HorizontalAlignment = 'center';
            app.CentralWavelengthSliderLabel.Layout.Row = 1;
            app.CentralWavelengthSliderLabel.Layout.Column = [1 2];
            app.CentralWavelengthSliderLabel.Text = 'Central Wavelength';
            app.CentralWavelengthSliderLabel.Enable = 'off';

            
            % Create StatusLabel
            app.StatusLabel = uilabel(app.MainGridLayout);
            app.StatusLabel.Layout.Row = 5;
            app.StatusLabel.Layout.Column = 2;
            app.StatusLabel.Text = 'Please select input files and calibration file(s).';

            % Create RunButton
            app.RunButton = uibutton(app.MainGridLayout, 'push');
            app.RunButton.Layout.Row = 5;
            app.RunButton.Layout.Column = 4;
            app.RunButton.Text = 'Run!';
            app.RunButton.Enable = 'off';
            app.RunButton.ButtonPushedFcn = createCallbackFcn(app, @RunButtonPushed, true);

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = RainbowSTORM

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)
            
            addpath('lib');
            addpath('lib/dwp_scripts');

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
end