classdef axial_calibration < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        AxialCalibrationLabel        matlab.ui.control.Label
        PixelsizenmEditField_2       matlab.ui.control.NumericEditField
        PixelsizenmEditField_2Label  matlab.ui.control.Label
        ExportButton                 matlab.ui.control.Button
        maxz1Label                   matlab.ui.control.Label
        minz1Label                   matlab.ui.control.Label
        EditField_4                  matlab.ui.control.NumericEditField
        EditField_3                  matlab.ui.control.NumericEditField
        maxz0Label                   matlab.ui.control.Label
        Minz0Label                   matlab.ui.control.Label
        EditField_2                  matlab.ui.control.NumericEditField
        EditField                    matlab.ui.control.NumericEditField
        Uploadnd2ortiffileButton     matlab.ui.control.Button
        UIAxes4_2                    matlab.ui.control.UIAxes
        UIAxes4                      matlab.ui.control.UIAxes
        UIAxes3                      matlab.ui.control.UIAxes
        UIAxes2_2                    matlab.ui.control.UIAxes
        UIAxes2                      matlab.ui.control.UIAxes
        ContextMenu                  matlab.ui.container.ContextMenu
        Menu                         matlab.ui.container.Menu
        Menu2                        matlab.ui.container.Menu
    end

    
    properties (Access = private)
        dir_inputpath % Description
        z
        fwhm0
        fwhm1
        z_simulated
        ratio
    end
    
    methods (Access = private)
    
        
        
       
        
%         function FormatTable(app)
%             Parameter=["z0 min";"z0 max";"z1 min";"z1 max"];
%             Value=[min(app.z);max(app.z);min(app.z);max(app.z)];
%             App.UITable.Data=table(Parameter,Value);
% 
%         end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
        end

        % Button pushed function: Uploadnd2ortiffileButton
        function Uploadnd2ortiffileButtonPushed(app, event)
            addpath('bf_func')
            A = SPLMload('f','nd2','double');
%             app.dir_inputpath = uigetdir();
%             app.InputFolderTextArea.Value = app.dir_inputpath;
             imagesc(app.UIAxes3,squeeze(mean(A,3)))
             A=double(squeeze(A));
             Nf = size(A,3);
             A_width=size(A,2);
             A0 = A(:,1:round(A_width/2),:);
             A1 = A(:,(round(A_width/2)+1):end,:);
             px = app.PixelsizenmEditField_2.Value;
             p3=round(Nf/2);
             A_width=size(A,2);
%              peak0 = app.thpeakdetectionthreshholdEditField.Value;
%              peak1 = app.stpeakdetectionthreshholdEditField.Value;
             [py0,px0] = find(A0(:,:,p3)==max(max(A0(:,:,p3))));
             [py1,px1] = find(A1(:,:,p3)==max(max(A1(:,:,p3))));
             
             imagesc(app.UIAxes4,A0(1:end,1:end,p3));hold(app.UIAxes4, 'on');
             scatter(app.UIAxes4,px0,py0,'*g')
             subplot 122;
             imagesc(app.UIAxes4_2,A1(1:end,1:end,p3));hold(app.UIAxes4_2, 'on');
             scatter(app.UIAxes4_2,px1,py1,'*g')

             aa=[];%Blinking image
             psf0 = [];
             spt= [];
             sptavg = [];
             psf1 = [];
             bw=5;
             w0=6;  % width of ROI in 0th order
             w1=6;  % width of ROI along x-axis in 1th order
                 for Nf = 1:size(A,3)
                     %         aa=A0([-w0:w0]+py0(n),[-w0:w0]+px0(n),Nf) - (A0([-w0:w0]+py0(n)+sft,[-w0:w0]+px0(n),Nf)+A0([-w0:w0]+py0(n)-sft,[-w0:w0]+px0(n),Nf))/2;
                     aa=A0([-w0:w0]+py0(1),[-w0:w0]+px0(1),Nf)-30 ;
                     psf0(1,:,Nf) = sum(aa((w0+1)-bw:(w0+1)+bw,:),2);
                     %           psf0(n,:,Nf) = sum(aa,2);
                     %         spt =A1new([-w0:w0]+py1new(n)+Offset,[-w1*1:w1*1]+px1new(n),Nf) - (A1new([-w0:w0]+py1new(n)+sft + Offset,[-w1*1:w1*1]+px1new(n),Nf)+A1new([-w0:w0]+py1new(n)-sft + Offset,[-w1*1:w1*1]+px1new(n),Nf))/2;
                     spt =A1([-w0:w0]+py1(1),[-w1*1:w1*1]+px1(1),Nf)-30 ;

                     sptavg(1,:)=sum(spt,1);
                     psf1(1,:,Nf) = sum(spt((w0+1)-bw:(w0+1)+bw,:),2);
                     %         psf1(n,:,Nf) = sum(spt,2);


                 end
                 psfY0=[];
                 psfY1=[];
                 psf2D0 = [];
                 psf2D1 = [];
                 yfit0=[];
                 yfit1=[];
                 Px = 110;
                 options = optimset('Display','off','TolFun',4e-16,'LargeScale','off');
                     for Nf =1:size(A,3)
                         
                         % fitting for spatial images
                         psfY0(1,:) =  psf0(1,:,Nf);
                         psfY0(1,:) = psfY0(1,:) - min(psfY0(1,:));

                         %         psfY0(n,:) = psfY0(n,:).*(psfY0(n,:)>0);
                         y0 = [1:size(psfY0(1,:),2)];
                         cy0(1,:) = sum(psfY0(1,:).*y0)/sum(psfY0(1,:));
                         sy0(1,:) = sqrt(sum(psfY0(1,:).*(abs(y0-cy0(1,:)).^2))/sum(psfY0(1,:)));
                         amp0(1,:) = max(psfY0(1,:));
                         par0(1,:) = [cy0(1,:),sy0(1,:),amp0(1,:)];

                         fp0D = fminunc(@fitgaussian1D,par0(1,:),options,psfY0(1,:),y0);

                         cy0fit(1,Nf) = fp0D(1);
                         sy0fit(1,Nf) = fp0D(2);
                         amp0fit(1,Nf) = fp0D(3);
                         y0new = [1:0.1:size(psfY0(1,:),2)];
                         yfit0(1,:) = amp0fit(1,Nf)*(exp(-0.5*(y0new-cy0fit(1,Nf)).^2./(sy0fit(1,Nf)^2)));
                         fwhm0(1,Nf) = sy0fit(1,Nf)*2.35*Px*0.8906; % 0.8621 is the constant between Thunderstorm and fitting
                         %         fwhm0px(n,Nf) = sy0fit(n,Nf);

                         % fitting for spatial images
                         psfY1(1,:) =  psf1(1,:,Nf);
                         psfY1(1,:) = psfY1(1,:) - min(psfY1(1,:));

                         %         psfY1(n,:) = psfY1(n,:).*(psfY1(n,:)>0);
                         y1 = [1:size(psfY1(1,:),2)];
                         cy1(1,:) = sum(psfY1(1,:).*y1)/sum(psfY1(1,:));
                         sy1(1,:) = sqrt(sum(psfY1(1,:).*(abs(y1-cy1(1,:)).^2))/sum(psfY1(1,:)));
                         amp1(1,:) = max(psfY1(1,:));
                         par1(1,:) = [cy1(1,:),sy1(1,:),amp1(1,:)];
                         try
                             fp1D = fminunc(@fitgaussian1D,par1(1,:),options,psfY1(1,:),y1);
                         end
                         cy1fit(1,Nf) = fp1D(1);
                         sy1fit(1,Nf) = fp1D(2);
                         amp1fit(1,Nf) = fp1D(3);
                         y1new = [1:0.1:size(psfY1,2)];
                         yfit1(1,:) = amp1fit(1,Nf)*(exp(-0.5*(y1new-cy1fit(1,Nf)).^2./(sy1fit(1,Nf)^2)));
                         fwhm1(1,Nf) = sy1fit(1,Nf)*2.35*Px*0.8906;
                         
           
                     end
                     step = 20;
                     z = -(Nf*step/2-step/2):step:(Nf*step/2-step/2);
                     zstt = -2000;
                     zend = 2000;
                     fwhm0new = [];
                     fwhm1new = [];

                     plot(app.UIAxes2,z,fwhm0(:),'ob','MarkerSize',4);
                     hold(app.UIAxes2,'on');
                     plot(app.UIAxes2,z,fwhm1(:),'or','MarkerSize',4);
                     ylim(app.UIAxes2,[300,1000])
                     app.z=z;
                     app.fwhm0=fwhm0;
                     app.fwhm1=fwhm1;

                     
                 


        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            delete(app)
            
        end

        % Button down function: UIAxes2
        function UIAxes2ButtonDown(app, event)
            
        end

        % Callback function
        function thpeakdetectionthreshholdEditFieldValueChanged(app, event)
            value = app.thpeakdetectionthreshholdEditField.Value;
            plot(app.UIAxes2,z,fwhm0(n,:),'ob','MarkerSize',4)
            ylim(app.UIAxes2,[0 8000])
            hold on;
            plot(app.UIAxes2,z,fwhm1(n,:),'or','MarkerSize',4);
        end

        % Value changed function: EditField, EditField_2, EditField_3, 
        % ...and 1 other component
        function EditField_4ValueChanged(app, event)
             value1 = app.EditField.Value;
             value2 = app.EditField_2.Value;
             value3 = app.EditField_3.Value;
             value4 = app.EditField_4.Value;
             znew=app.z;
             ab=find(znew>=value1); ab=ab(1);
             cd=find(znew<=value2); cd=cd(end);
             ef=find(znew>=value3); ef=ef(1);
             gh=find(znew<=value4); gh=gh(end);
             z0=znew(ab:cd);
             z1=znew(ef:gh);
             fwhm0=app.fwhm0;
             fwhm1=app.fwhm1;
             hold(app.UIAxes2,'off');
             plot(app.UIAxes2,z0,fwhm0(ab:cd),'ob','MarkerSize',4);
             hold(app.UIAxes2,'on');
             plot(app.UIAxes2,z1,fwhm1(ef:gh),'or','MarkerSize',4);
             ylim(app.UIAxes2,[300,1000])
             z_simulated=-2000:1:2000;
             fwhm1=fwhm1(ef:gh);
             fwhm0=fwhm0(ab:cd);
             f1=polyfit(z1,fwhm1',2);
             ze1=polyfit(z0,fwhm0',2);
             first_simulated=f1(1).*z_simulated.^2+f1(2)*z_simulated+f1(3);
             zeroth_simulated=ze1(1).*z_simulated.^2+ze1(2)*z_simulated+ze1(3);
             hold(app.UIAxes2,'on'); plot(app.UIAxes2,z_simulated,first_simulated);
             hold(app.UIAxes2,'on'); plot(app.UIAxes2,z_simulated,zeroth_simulated);
             ratio=first_simulated./zeroth_simulated;
             maximum=find(islocalmax(ratio));
             minimum=find(islocalmin(ratio));
             ratio=ratio(maximum:minimum);
             z_simulated=z_simulated(maximum:minimum);
             plot(app.UIAxes2_2,z_simulated,ratio);
             app.z_simulated=z_simulated;
             app.ratio=ratio;
%             z1=z(80:value);
%             hold on; plot(app.UIAxes2,z1,fwhm1,'o');
%             hold on; plot(app.UIAxes2,z_simulated,first_simulated);
%             hold on; plot(app.UIAxes2,z_simulated,zeroth_simulated);
%             plot(app.UIAxes2_2,z_simulated,ratio)
        end

        % Value changed function: PixelsizenmEditField_2
        function PixelsizenmEditField_2ValueChanged(app, event)
            value = app.PixelsizenmEditField_2.Value;
            
        end

        % Button pushed function: ExportButton
        function ExportButtonPushed(app, event)
            cali_array=[app.z_simulated;app.ratio];
            cali_array=cali_array';
            save('3d_cal','cali_array');
            savefile='3d_cal.csv';
            dlmwrite(savefile,cali_array);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 696 525];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, 'FWHM vs. Z')
            xlabel(app.UIAxes2, 'z position (nm)')
            ylabel(app.UIAxes2, 'FWHM (nm)')
            zlabel(app.UIAxes2, 'Z')
            app.UIAxes2.ButtonDownFcn = createCallbackFcn(app, @UIAxes2ButtonDown, true);
            app.UIAxes2.Position = [13 39 324 185];

            % Create UIAxes2_2
            app.UIAxes2_2 = uiaxes(app.UIFigure);
            title(app.UIAxes2_2, 'Calibration Curve')
            xlabel(app.UIAxes2_2, 'z position (nm)')
            ylabel(app.UIAxes2_2, 'FWHM Ratio')
            zlabel(app.UIAxes2_2, 'Z')
            app.UIAxes2_2.Position = [456 39 241 185];

            % Create UIAxes3
            app.UIAxes3 = uiaxes(app.UIFigure);
            zlabel(app.UIAxes3, 'Z')
            app.UIAxes3.XTick = [];
            app.UIAxes3.YTick = [];
            app.UIAxes3.Position = [283 387 412 116];

            % Create UIAxes4
            app.UIAxes4 = uiaxes(app.UIFigure);
            title(app.UIAxes4, 'Zeroth Order')
            zlabel(app.UIAxes4, 'Z')
            app.UIAxes4.XTick = [];
            app.UIAxes4.YTick = [];
            app.UIAxes4.Position = [12 247 325 133];

            % Create UIAxes4_2
            app.UIAxes4_2 = uiaxes(app.UIFigure);
            title(app.UIAxes4_2, 'First Order')
            zlabel(app.UIAxes4_2, 'Z')
            app.UIAxes4_2.XTick = [];
            app.UIAxes4_2.YTick = [];
            app.UIAxes4_2.Position = [363 247 318 133];

            % Create Uploadnd2ortiffileButton
            app.Uploadnd2ortiffileButton = uibutton(app.UIFigure, 'push');
            app.Uploadnd2ortiffileButton.ButtonPushedFcn = createCallbackFcn(app, @Uploadnd2ortiffileButtonPushed, true);
            app.Uploadnd2ortiffileButton.Position = [78 463 122 23];
            app.Uploadnd2ortiffileButton.Text = 'Upload nd2 or tif file';

            % Create EditField
            app.EditField = uieditfield(app.UIFigure, 'numeric');
            app.EditField.ValueChangedFcn = createCallbackFcn(app, @EditField_4ValueChanged, true);
            app.EditField.Position = [343 212 100 22];
            app.EditField.Value = -2000;

            % Create EditField_2
            app.EditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.EditField_2.ValueChangedFcn = createCallbackFcn(app, @EditField_4ValueChanged, true);
            app.EditField_2.Position = [343 170 100 22];
            app.EditField_2.Value = 2000;

            % Create Minz0Label
            app.Minz0Label = uilabel(app.UIFigure);
            app.Minz0Label.Position = [376 233 40 22];
            app.Minz0Label.Text = 'Min z0';

            % Create maxz0Label
            app.maxz0Label = uilabel(app.UIFigure);
            app.maxz0Label.Position = [374 191 44 22];
            app.maxz0Label.Text = 'max z0';

            % Create EditField_3
            app.EditField_3 = uieditfield(app.UIFigure, 'numeric');
            app.EditField_3.ValueChangedFcn = createCallbackFcn(app, @EditField_4ValueChanged, true);
            app.EditField_3.Position = [346 117 100 22];
            app.EditField_3.Value = -2000;

            % Create EditField_4
            app.EditField_4 = uieditfield(app.UIFigure, 'numeric');
            app.EditField_4.ValueChangedFcn = createCallbackFcn(app, @EditField_4ValueChanged, true);
            app.EditField_4.Position = [346 75 100 22];
            app.EditField_4.Value = 2000;

            % Create minz1Label
            app.minz1Label = uilabel(app.UIFigure);
            app.minz1Label.Position = [379 138 40 22];
            app.minz1Label.Text = 'min z1';

            % Create maxz1Label
            app.maxz1Label = uilabel(app.UIFigure);
            app.maxz1Label.Position = [377 96 44 22];
            app.maxz1Label.Text = 'max z1';

            % Create ExportButton
            app.ExportButton = uibutton(app.UIFigure, 'push');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.ExportButton.Position = [346 17 100 23];
            app.ExportButton.Text = 'Export';

            % Create PixelsizenmEditField_2Label
            app.PixelsizenmEditField_2Label = uilabel(app.UIFigure);
            app.PixelsizenmEditField_2Label.HorizontalAlignment = 'right';
            app.PixelsizenmEditField_2Label.Position = [39 417 84 22];
            app.PixelsizenmEditField_2Label.Text = 'Pixel size (nm)';

            % Create PixelsizenmEditField_2
            app.PixelsizenmEditField_2 = uieditfield(app.UIFigure, 'numeric');
            app.PixelsizenmEditField_2.ValueChangedFcn = createCallbackFcn(app, @PixelsizenmEditField_2ValueChanged, true);
            app.PixelsizenmEditField_2.Position = [138 417 100 22];
            app.PixelsizenmEditField_2.Value = 110;

            % Create AxialCalibrationLabel
            app.AxialCalibrationLabel = uilabel(app.UIFigure);
            app.AxialCalibrationLabel.FontSize = 14;
            app.AxialCalibrationLabel.Position = [301 504 106 22];
            app.AxialCalibrationLabel.Text = 'Axial Calibration';

            % Create ContextMenu
            app.ContextMenu = uicontextmenu(app.UIFigure);

            % Create Menu
            app.Menu = uimenu(app.ContextMenu);
            app.Menu.Text = 'Menu';

            % Create Menu2
            app.Menu2 = uimenu(app.ContextMenu);
            app.Menu2.Text = 'Menu2';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = axial_calibration

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.UIFigure)

                % Execute the startup function
                runStartupFcn(app, @startupFcn)
            else

                % Focus the running singleton app
                figure(runningApp.UIFigure)

                app = runningApp;
            end

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