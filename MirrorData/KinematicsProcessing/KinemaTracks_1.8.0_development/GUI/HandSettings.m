function varargout = HandSettings(varargin)
%m-function for the GUI KinemaTracks

%get globals
global LHO;
global GHO;
global SY;
global FL;

if nargin == 0  % LAUNCH GUI
    
    %check if figure already exists
    h = findall(0,'tag','Hand Settings');
    
    if (isempty(h))
        %Launch the figure
        fig = openfig(mfilename,'reuse');
        set(fig,'NumberTitle','off', 'Name','Hand Settings');
        set(fig,'Visible','off');
        handles = guihandles(fig);
        
        
        % GET HAND INFORMATION FROM VARIABLES
        subjectname=get(LHO,'subjectname');
        handside=get(LHO,'handside');        
        rf=get(LHO,'fingerradius');
        ab=get(LHO,'lengthab');
        bc=get(LHO,'lengthbc');
        ct=get(LHO,'lengthct');
        mcp=get(LHO,'metacarpaljoints');
        al1=get(LHO,'lengthdorsum');
        al2=get(LHO,'lengthlowerarm');
        al3=get(LHO,'lengthupperarm');
        sl=get(LHO,'lengthsensor');
        sh =get(GHO,'shoulder');
        wr = get(LHO,'armjoints'); 
        wr=wr(1,1:3);
        
        if numel(sl)==1 % in previous version of kinematracks, there was only on sensor-tip distance (=lengthsensor) for one, finger. If such an old format is detected, the distance is copied for all fingers
            sl=repmat(sl,1,numel(ab));
        end
            
        
        % SET SOME STANDARD VALUES
        if isempty(handside)
            handside='left'; %standardvalue if not defined
        end    
        set(handles.handside_popup,'String',{'left';'right'});
        value=getvalue(handles.handside_popup,handside);
        set(handles.handside_popup,'Value',value);
        
        % FILL IN EDITS (if the value already exists)
        if ~isnan(sl)
            set(handles.sensor_lengthI_edit,  'String',num2str(sl(1)));
            set(handles.sensor_lengthII_edit, 'String',num2str(sl(2)));
            set(handles.sensor_lengthIII_edit,'String',num2str(sl(3)));
            set(handles.sensor_lengthIV_edit, 'String',num2str(sl(4)));
            set(handles.sensor_lengthV_edit,  'String',num2str(sl(5)));

        end
        
        set(handles.subjectname_edit,  'String',subjectname);

        if ~isempty(rf)
        set(handles.rFI_edit,  'String',num2str(rf(1)));
        set(handles.rFII_edit, 'String',num2str(rf(2)));
        set(handles.rFIII_edit,'String',num2str(rf(3)));
        set(handles.rFIV_edit, 'String',num2str(rf(4)));
        set(handles.rFV_edit,  'String',num2str(rf(5)));
        end
        if ~isempty(ab)
        set(handles.ABI_edit,  'String',num2str(ab(1)));
        set(handles.ABII_edit, 'String',num2str(ab(2)));
        set(handles.ABIII_edit,'String',num2str(ab(3)));
        set(handles.ABIV_edit, 'String',num2str(ab(4)));
        set(handles.ABV_edit,  'String',num2str(ab(5)));
        end
        if ~isempty(bc)
        set(handles.BCI_edit,  'String',num2str(bc(1)));
        set(handles.BCII_edit, 'String',num2str(bc(2)));
        set(handles.BCIII_edit,'String',num2str(bc(3)));
        set(handles.BCIV_edit, 'String',num2str(bc(4)));
        set(handles.BCV_edit,  'String',num2str(bc(5)));
        end
        if ~isempty(ct)
        set(handles.CTI_edit,  'String',num2str(ct(1)));
        set(handles.CTII_edit, 'String',num2str(ct(2)));
        set(handles.CTIII_edit,'String',num2str(ct(3)));
        set(handles.CTIV_edit, 'String',num2str(ct(4)));
        set(handles.CTV_edit,  'String',num2str(ct(5)));
        end
        if ~isempty(mcp)
        numJoints=size(mcp,1);
        for ii=1:numJoints
            switch ii
                case 1  
                    if ~isnan(mcp(1,:))
                        set(handles.AxI_edit,'String',num2str(mcp(1,1)));
                        set(handles.AyI_edit,'String',num2str(mcp(1,2)));
                        set(handles.AzI_edit,'String',num2str(mcp(1,3)));
                    end
                case 2
                    if ~isnan(mcp(2,:))
                        set(handles.AxII_edit,'String',num2str(mcp(2,1)));
                        set(handles.AyII_edit,'String',num2str(mcp(2,2)));
                        set(handles.AzII_edit,'String',num2str(mcp(2,3))); 
                    end
                case 3
                    if ~isnan(mcp(3,:))
                        set(handles.AxIII_edit,'String',num2str(mcp(3,1)));
                        set(handles.AyIII_edit,'String',num2str(mcp(3,2)));
                        set(handles.AzIII_edit,'String',num2str(mcp(3,3)));
                    end
                case 4
                    if ~isnan(mcp(4,:))
                        set(handles.AxIV_edit,'String',num2str(mcp(4,1)));
                        set(handles.AyIV_edit,'String',num2str(mcp(4,2)));
                        set(handles.AzIV_edit,'String',num2str(mcp(4,3)));
                    end
                case 5
                    if ~isnan(mcp(5,:))
                        set(handles.AxV_edit,'String',num2str(mcp(5,1)));
                        set(handles.AyV_edit,'String',num2str(mcp(5,2)));
                        set(handles.AzV_edit,'String',num2str(mcp(5,3)));
                    end
            end
        end
        
        if ~isempty(sh)
        set(handles.shoulder_x_edit,  'String',num2str(sh(1)));
        set(handles.shoulder_y_edit,  'String',num2str(sh(2)));
        set(handles.shoulder_z_edit,  'String',num2str(sh(3)));
        end
        if ~isempty(wr)
            set(handles.wrist_x_edit, 'String',num2str(wr(1)));
            set(handles.wrist_y_edit, 'String',num2str(wr(2)));
            set(handles.wrist_z_edit, 'String',num2str(wr(3)));
        end
        if ~isempty(al1)
        set(handles.arm_length1_edit,  'String',num2str(al1));
        end
        if ~isempty(al2)
        set(handles.arm_length2_edit,  'String',num2str(al2));
        end
        if ~isempty(al3)
        set(handles.arm_length3_edit,  'String',num2str(al3));
        end
        

        end
        
        
        %listboxes for sensoridentifier
        
        set(handles.P1_C1_handle_edit,'Enable','off');                     % the editors displaying the port handle are always off, because the user is not able to change them
        set(handles.P1_C2_handle_edit,'Enable','off');
        set(handles.P2_C1_handle_edit,'Enable','off');
        set(handles.P2_C2_handle_edit,'Enable','off');
        set(handles.P3_C1_handle_edit,'Enable','off');
        set(handles.P3_C2_handle_edit,'Enable','off');
        set(handles.P4_C1_handle_edit,'Enable','off');
        set(handles.P4_C2_handle_edit,'Enable','off');
        
        
        % SETUP SENSOR IDENTIFIER FOR DIFFERENT PROGRAM CASES
        sensoridentifier=get(LHO,'sensoridentifier');
        
        if isempty(sensoridentifier) && ~FL.toolsinit                      % sensoridentifier is not load, tools are not intialized: everything has to be deactivated
            ca=1;
        elseif isempty(sensoridentifier) && FL.toolsinit                   % sensoridentifier is not load, tools are initialized:    availablesensors must be standard, initialized ports must be active
            ca=2;
        elseif ~isempty(sensoridentifier) && ~FL.toolsinit                 % sensoridentifier is load, tools are not initialized:    show all available and selected sensors and tools from load file, but deactivate them
            ca=3;
        elseif ~isempty(sensoridentifier) &&  FL.toolsinit                 % sensoridentifier is load, tools are initialized:        show the available and selected snsors and tools and activate them      
            ca=4;
        end
        
        
        % WORK ON CASES
        switch ca
            case 1 
                set(handles.availablesensors_listbox,'Enable','off');
                set(handles.P1_C1_tool_edit,'Enable','off');
                set(handles.P1_C2_tool_edit,'Enable','off');
                set(handles.P2_C1_tool_edit,'Enable','off');
                set(handles.P2_C2_tool_edit,'Enable','off');
                set(handles.P3_C1_tool_edit,'Enable','off');
                set(handles.P3_C2_tool_edit,'Enable','off');
                set(handles.P4_C1_tool_edit,'Enable','off');
                set(handles.P4_C2_tool_edit,'Enable','off');
                set(handles.P1_C1_button,'Enable','off');
                set(handles.P1_C2_button,'Enable','off');
                set(handles.P2_C1_button,'Enable','off');
                set(handles.P2_C2_button,'Enable','off');
                set(handles.P3_C1_button,'Enable','off');
                set(handles.P3_C2_button,'Enable','off');
                set(handles.P4_C1_button,'Enable','off');
                set(handles.P4_C2_button,'Enable','off');
            case 2
                
                % Turn off everything before,...
                set(handles.availablesensors_listbox,'Enable','off');
                set(handles.P1_C1_tool_edit,'Enable','off');
                set(handles.P1_C2_tool_edit,'Enable','off');
                set(handles.P2_C1_tool_edit,'Enable','off');
                set(handles.P2_C2_tool_edit,'Enable','off');
                set(handles.P3_C1_tool_edit,'Enable','off');
                set(handles.P3_C2_tool_edit,'Enable','off');
                set(handles.P4_C1_tool_edit,'Enable','off');
                set(handles.P4_C2_tool_edit,'Enable','off');
                set(handles.P1_C1_button,'Enable','off');
                set(handles.P1_C2_button,'Enable','off');
                set(handles.P2_C1_button,'Enable','off');
                set(handles.P2_C2_button,'Enable','off');
                set(handles.P3_C1_button,'Enable','off');
                set(handles.P3_C2_button,'Enable','off');
                set(handles.P4_C1_button,'Enable','off');
                set(handles.P4_C2_button,'Enable','off');
                
                availablesensors={'Sensor Thumb';'Sensor Index';'Sensor Middle';'Sensor Ring';'Sensor Little'; 'Sensor Wrist';'Sensor Reference'}; 
                set(handles.availablesensors_listbox,'Enable','on');
                set(handles.availablesensors_listbox,'String',availablesensors); 
                % ... then turn on tools
                toolID=get(SY,'toolID');
                for ii=1:size(toolID,2)
                   if ~isempty(toolID{ii})
                       switch ii
                           case 1
                               set(handles.P1_C1_button,'Enable','on');
                               set(handles.P1_C1_tool_edit,'Enable','on');
                               set(handles.P1_C1_handle_edit,'String',toolID{ii});
                           case 2
                               set(handles.P1_C2_button,'Enable','on');
                               set(handles.P1_C2_tool_edit,'Enable','on');
                               set(handles.P1_C2_handle_edit,'String',toolID{ii});
                           case 3
                               set(handles.P2_C1_button,'Enable','on');
                               set(handles.P2_C1_tool_edit,'Enable','on');
                               set(handles.P2_C1_handle_edit,'String',toolID{ii});
                           case 4
                               set(handles.P2_C2_button,'Enable','on');
                               set(handles.P2_C2_tool_edit,'Enable','on');
                               set(handles.P2_C2_handle_edit,'String',toolID{ii});
                           case 5
                               set(handles.P3_C1_button,'Enable','on');
                               set(handles.P3_C1_tool_edit,'Enable','on');
                               set(handles.P3_C1_handle_edit,'String',toolID{ii});
                           case 6
                               set(handles.P3_C2_button,'Enable','on');
                               set(handles.P3_C2_tool_edit,'Enable','on');
                               set(handles.P3_C2_handle_edit,'String',toolID{ii});
                           case 7
                               set(handles.P4_C1_button,'Enable','on');
                               set(handles.P4_C1_tool_edit,'Enable','on');
                               set(handles.P4_C1_handle_edit,'String',toolID{ii});
                           case 8
                               set(handles.P4_C2_button,'Enable','on');
                               set(handles.P4_C2_tool_edit,'Enable','on');
                               set(handles.P4_C2_handle_edit,'String',toolID{ii});
                       end
                   end
                 end
                
            case 3
                % 1. Turn every button, edit off
                set(handles.availablesensors_listbox,'Enable','off');
                set(handles.P1_C1_tool_edit,'Enable','off');
                set(handles.P1_C2_tool_edit,'Enable','off');
                set(handles.P2_C1_tool_edit,'Enable','off');
                set(handles.P2_C2_tool_edit,'Enable','off');
                set(handles.P3_C1_tool_edit,'Enable','off');
                set(handles.P3_C2_tool_edit,'Enable','off');
                set(handles.P4_C1_tool_edit,'Enable','off');
                set(handles.P4_C2_tool_edit,'Enable','off');
                set(handles.P1_C1_button,'Enable','off');
                set(handles.P1_C2_button,'Enable','off');
                set(handles.P2_C1_button,'Enable','off');
                set(handles.P2_C2_button,'Enable','off');
                set(handles.P3_C1_button,'Enable','off');
                set(handles.P3_C2_button,'Enable','off');
                set(handles.P4_C1_button,'Enable','off');
                set(handles.P4_C2_button,'Enable','off');
                
                % 2. Actiate enabled tools in GUI, write down there handles
                toolID=get(SY,'toolID');
                for ii=1:size(toolID,2)
                   if ~isempty(toolID{ii})
                       switch ii
                           case 1
                               set(handles.P1_C1_handle_edit,'String',toolID{ii});
                           case 2
                               set(handles.P1_C2_handle_edit,'String',toolID{ii});
                           case 3
                               set(handles.P2_C1_handle_edit,'String',toolID{ii});
                           case 4
                               set(handles.P2_C2_handle_edit,'String',toolID{ii});
                           case 5
                               set(handles.P3_C1_handle_edit,'String',toolID{ii});
                           case 6
                               set(handles.P3_C2_handle_edit,'String',toolID{ii});
                           case 7
                               set(handles.P4_C1_handle_edit,'String',toolID{ii});
                           case 8
                               set(handles.P4_C2_handle_edit,'String',toolID{ii});
                       end
                   end
                end
                
                % 3. Fill in Sensor Names into the port of tool
                availablesensors={'Sensor Thumb';'Sensor Index';'Sensor Middle';'Sensor Ring';'Sensor Little'; 'Sensor Wrist';'Sensor Reference'}; 
                allsensors={'Sensor Thumb';'Sensor Index';'Sensor Middle';'Sensor Ring';'Sensor Little'; 'Sensor Wrist';'';'Sensor Reference'}; 
                tempsensors=allsensors; % make copy of allsensors 
                set(handles.availablesensors_listbox,'String',availablesensors); 
                
                handlelist{1}=get(handles.P1_C1_handle_edit,'String');
                handlelist{2}=get(handles.P1_C2_handle_edit,'String');
                handlelist{3}=get(handles.P2_C1_handle_edit,'String');
                handlelist{4}=get(handles.P2_C2_handle_edit,'String');
                handlelist{5}=get(handles.P3_C1_handle_edit,'String');
                handlelist{6}=get(handles.P3_C2_handle_edit,'String');
                handlelist{7}=get(handles.P4_C1_handle_edit,'String');
                handlelist{8}=get(handles.P4_C2_handle_edit,'String');                     
                handlelist_cmp={'0A','0B','0C','0D','0E','0F','10','11'};                  % this are the port of the WAVE/Aurora System
                
                numtools=length(sensoridentifier);
                for ii=1:numtools
                    nameoftool=getnameoftool(sensoridentifier(ii));
                    for aa=1:8 % maximal sensors
                         if strcmp(handlelist{1},handlelist_cmp{ii})
                            set(handles.P1_C1_tool_edit,'String',nameoftool);
                            set(handles.P1_C1_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         elseif strcmp(handlelist{2},handlelist_cmp{ii})
                            set(handles.P1_C2_tool_edit,'String',nameoftool);
                            set(handles.P1_C2_button,'String','<-');
                            tempsensors{getnumoftool(ii)}='';
                         elseif strcmp(handlelist{3},handlelist_cmp{ii})
                            set(handles.P2_C1_tool_edit,'String',nameoftool);
                            set(handles.P2_C1_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         elseif strcmp(handlelist{4},handlelist_cmp{ii})
                            set(handles.P2_C2_tool_edit,'String',nameoftool);
                            set(handles.P2_C2_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         elseif strcmp(handlelist{5},handlelist_cmp{ii})
                            set(handles.P3_C1_tool_edit,'String',nameoftool);
                            set(handles.P3_C1_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         elseif strcmp(handlelist{6},handlelist_cmp{ii})
                            set(handles.P3_C2_tool_edit,'String',nameoftool);
                            set(handles.P3_C2_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         elseif strcmp(handlelist{7},handlelist_cmp{ii})
                            set(handles.P4_C1_tool_edit,'String',nameoftool);
                            set(handles.P4_C1_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         elseif strcmp(handlelist{8},handlelist_cmp{ii})
                            set(handles.P4_C2_tool_edit,'String',nameoftool); 
                            set(handles.P4_C2_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         end
                    end
                end
                availablesensors=tempsensors(~strcmp(tempsensors,''));
                set(handles.availablesensors_listbox,'String',availablesensors); 
 
            case 4
                % 1. Turn every button, edit off
                set(handles.availablesensors_listbox,'Enable','off');
                set(handles.P1_C1_tool_edit,'Enable','off');
                set(handles.P1_C2_tool_edit,'Enable','off');
                set(handles.P2_C1_tool_edit,'Enable','off');
                set(handles.P2_C2_tool_edit,'Enable','off');
                set(handles.P3_C1_tool_edit,'Enable','off');
                set(handles.P3_C2_tool_edit,'Enable','off');
                set(handles.P4_C1_tool_edit,'Enable','off');
                set(handles.P4_C2_tool_edit,'Enable','off');
                set(handles.P1_C1_button,'Enable','off');
                set(handles.P1_C2_button,'Enable','off');
                set(handles.P2_C1_button,'Enable','off');
                set(handles.P2_C2_button,'Enable','off');
                set(handles.P3_C1_button,'Enable','off');
                set(handles.P3_C2_button,'Enable','off');
                set(handles.P4_C1_button,'Enable','off');
                set(handles.P4_C2_button,'Enable','off');
                
                % 2. Actiate enabled tools in GUI, write down there handles
                toolID=get(SY,'toolID');
                for ii=1:size(toolID,2)
                   if ~isempty(toolID{ii})
                       switch ii
                           case 1
                               set(handles.P1_C1_button,'Enable','on');
                               set(handles.P1_C1_tool_edit,'Enable','on');
                               set(handles.P1_C1_handle_edit,'String',toolID{ii});
                           case 2
                               set(handles.P1_C2_button,'Enable','on');
                               set(handles.P1_C2_tool_edit,'Enable','on');
                               set(handles.P1_C2_handle_edit,'String',toolID{ii});
                           case 3
                               set(handles.P2_C1_button,'Enable','on');
                               set(handles.P2_C1_tool_edit,'Enable','on');
                               set(handles.P2_C1_handle_edit,'String',toolID{ii});
                           case 4
                               set(handles.P2_C2_button,'Enable','on');
                               set(handles.P2_C2_tool_edit,'Enable','on');
                               set(handles.P2_C2_handle_edit,'String',toolID{ii});
                           case 5
                               set(handles.P3_C1_button,'Enable','on');
                               set(handles.P3_C1_tool_edit,'Enable','on');
                               set(handles.P3_C1_handle_edit,'String',toolID{ii});
                           case 6
                               set(handles.P3_C2_button,'Enable','on');
                               set(handles.P3_C2_tool_edit,'Enable','on');
                               set(handles.P3_C2_handle_edit,'String',toolID{ii});
                           case 7
                               set(handles.P4_C1_button,'Enable','on');
                               set(handles.P4_C1_tool_edit,'Enable','on');
                               set(handles.P4_C1_handle_edit,'String',toolID{ii});
                           case 8
                               set(handles.P4_C2_button,'Enable','on');
                               set(handles.P4_C2_tool_edit,'Enable','on');
                               set(handles.P4_C2_handle_edit,'String',toolID{ii});
                       end
                   end
                end
                
                % 3. Fill in Sensor Names into the port of tool
                availablesensors={'Sensor Thumb';'Sensor Index';'Sensor Middle';'Sensor Ring';'Sensor Little'; 'Sensor Wrist';'Sensor Reference'}; 
                allsensors={'Sensor Thumb';'Sensor Index';'Sensor Middle';'Sensor Ring';'Sensor Little'; 'Sensor Wrist';'';'Sensor Reference'}; 
                tempsensors=allsensors; % make copy of allsensors 
                set(handles.availablesensors_listbox,'Enable','on');
                set(handles.availablesensors_listbox,'String',availablesensors); 
                
                handlelist{1}=get(handles.P1_C1_handle_edit,'String');
                handlelist{2}=get(handles.P1_C2_handle_edit,'String');
                handlelist{3}=get(handles.P2_C1_handle_edit,'String');
                handlelist{4}=get(handles.P2_C2_handle_edit,'String');
                handlelist{5}=get(handles.P3_C1_handle_edit,'String');
                handlelist{6}=get(handles.P3_C2_handle_edit,'String');
                handlelist{7}=get(handles.P4_C1_handle_edit,'String');
                handlelist{8}=get(handles.P4_C2_handle_edit,'String');                     
                handlelist_cmp={'0A','0B','0C','0D','0E','0F','10','11'};                  % this are the port of the WAVE/Aurora System
                
                numtools=length(sensoridentifier);
                for ii=1:numtools
                    nameoftool=getnameoftool(sensoridentifier(ii));
                    for aa=1:8 % maximal sensors
                         if strcmp(handlelist{1},handlelist_cmp{ii})
                            set(handles.P1_C1_tool_edit,'String',nameoftool);
                            set(handles.P1_C1_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         elseif strcmp(handlelist{2},handlelist_cmp{ii})
                            set(handles.P1_C2_tool_edit,'String',nameoftool);
                            set(handles.P1_C2_button,'String','<-');
                            tempsensors{getnumoftool(ii)}='';
                         elseif strcmp(handlelist{3},handlelist_cmp{ii})
                            set(handles.P2_C1_tool_edit,'String',nameoftool);
                            set(handles.P2_C1_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         elseif strcmp(handlelist{4},handlelist_cmp{ii})
                            set(handles.P2_C2_tool_edit,'String',nameoftool);
                            set(handles.P2_C2_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         elseif strcmp(handlelist{5},handlelist_cmp{ii})
                            set(handles.P3_C1_tool_edit,'String',nameoftool);
                            set(handles.P3_C1_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         elseif strcmp(handlelist{6},handlelist_cmp{ii})
                            set(handles.P3_C2_tool_edit,'String',nameoftool);
                            set(handles.P3_C2_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         elseif strcmp(handlelist{7},handlelist_cmp{ii})
                            set(handles.P4_C1_tool_edit,'String',nameoftool);
                            set(handles.P4_C1_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         elseif strcmp(handlelist{8},handlelist_cmp{ii})
                            set(handles.P4_C2_tool_edit,'String',nameoftool); 
                            set(handles.P4_C2_button,'String','<-');
                            tempsensors{getnumoftool(nameoftool)}='';
                         end
                    end
                end
                availablesensors=tempsensors(~strcmp(tempsensors,''));
                set(handles.availablesensors_listbox,'String',availablesensors); 
                
            otherwise
        end
    else      
    %Figure exists ==> error
    troubles('Not allowed to start multiple Windows.',' Window is already open.');
    %bring figure to front
    figure(h);
    return
        
    end;

    % Generate a structure of handles to pass to callbacks, and store it.
    handles = guihandles(fig);
    set(fig,'Visible','on');

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
    try
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    catch exception
        rethrow(exception);
    end

end
end %end of KinemaTracks


%######################## SENSOR IDENTIFIER ###############################
function varargout = Add_Button_Callback(h,~,handles,varargin)

boxcontent1 =get(handles.availablesensors_listbox,'String'); % get current content of listbox left
selection_id=get(handles.availablesensors_listbox,'Value');  % get current value of listbox left
selection_string=boxcontent1{selection_id}; % get the string for this value
boxcontent1{selection_id}=''; % clear the cell of the selected string
remain_id = ~cellfun('isempty', boxcontent1); % find the "remaining" cells (the one that are not selected)
boxcontent1_new=boxcontent1(remain_id);
if selection_id==numel(boxcontent1)
    set(handles.availablesensors_listbox,'Value',numel(boxcontent1)-1);
end

set(handles.availablesensors_listbox,'String',boxcontent1_new); % write the remaining cells to the left listbox

boxcontent2 = get(handles.selectedsensors_listbox,'String'); % get the content of right listbox
if isempty(boxcontent2) % empty listboxes result in erors, replace the empty entrys with ''
    boxcontent2{1}='';
    set(handles.selectedsensors_listbox,'Value',1);
    set(handles.selectedsensors_listbox,'String',boxcontent2)
end
    
value2      = get(handles.selectedsensors_listbox,'Value');  % get the value of the right listbox
boxcontent2new = cell(numel(boxcontent2)+1,1);  % create a new cell array, increasing the number of elements + 1. (space for the new selection)

% keep the contant smaller than the seleced index at same position, put the
% new selected string to the selected value and shift the contant greater
% than the selected index to a higher index +1;
for ii=1:length(boxcontent2new) 
    if ii<value2
        boxcontent2_new{ii}=boxcontent2{ii};
    elseif ii==value2
        boxcontent2_new{ii}=selection_string;
    elseif ii>value2
        boxcontent2_new{ii}=boxcontent2{ii-1};
    end
end

set(handles.selectedsensors_listbox,'String',boxcontent2_new);


if numel(boxcontent2_new)>=1 && ~strcmp(boxcontent2_new{1},'')
    set(handles.remove_button,'Enable','on');
else
    set(handles.remove_button,'Enable','off');
end
if numel(boxcontent1_new)>=1 && ~strcmp(boxcontent1_new{1},'')
    set(handles.add_button,'Enable','on');
else
    set(handles.add_button,'Enable','off');
end
    
end

function varargout = Remove_Button_Callback(h,~,handles,varargin)
boxcontent1 =get(handles.selectedsensors_listbox,'String'); % get current content of listbox left
selection_id=get(handles.selectedsensors_listbox,'Value');  % get current value of listbox left
selection_string=boxcontent1{selection_id}; % get the string for this value
boxcontent1{selection_id}=''; % clear the cell of the selected string
remain_id = ~cellfun('isempty', boxcontent1); % find the "remaining" cells (the one that are not selected)
boxcontent1_new=boxcontent1(remain_id);
if selection_id==numel(boxcontent1)
    set(handles.selectedsensors_listbox,'Value',numel(boxcontent1)-1);
end
set(handles.selectedsensors_listbox,'String',boxcontent1_new); % write the remaining cells to the left listbox

boxcontent2=get(handles.availablesensors_listbox,'String'); % get the content of right listbox
if isempty(boxcontent2) % empty listboxes result in erors, replace the empty entrys with ''
    boxcontent2{1}='';
    set(handles.availablesensors_listbox,'Value',1);
    set(handles.availablesensors_listbox,'String',boxcontent2)
end

value2     = get(handles.availablesensors_listbox,'Value');  % get the value of the right listbox
boxcontent2new = cell(numel(boxcontent2)+1,1);  % create a new cell array, increasing the number of elements + 1. (space for the new selection)

% keep the contant smaller than the seleced index at same position, put the
% new selected string to the selected value and shift the contant greater
% than the selected index to a higher index +1;
for ii=1:length(boxcontent2new) 
    if ii<value2
        boxcontent2_new{ii}=boxcontent2{ii};
    elseif ii==value2
        boxcontent2_new{ii}=selection_string;
    elseif ii>value2
        boxcontent2_new{ii}=boxcontent2{ii-1};
    end
end

set(handles.availablesensors_listbox,'String',boxcontent2_new);

if numel(boxcontent2_new)>=1 && ~strcmp(boxcontent2_new{1},'')
    set(handles.add_button,'Enable','on');
else
    set(handles.add_button,'Enable','off');
end
if numel(boxcontent1_new)>=1 && ~strcmp(boxcontent1_new{1},'')
    set(handles.remove_button,'Enable','on');
else
    set(handles.remove_button,'Enable','off');
end

end

%######################### FIND WRIST #####################################

function varargout = Wrist_Button_Callback(h,~,handles,varargin)

global LHO;
global GHO;

LHO.armjoints=nan(5,7);
GHO.armjoints=nan(5,7);
LHO = determinewrist(LHO); % estimate wrist position

wr=get(LHO,'armjoints'); wr=wr(1,1:3);

set(handles.wrist_x_edit,'String', num2str(wr(1)));
set(handles.wrist_y_edit,'String', num2str(wr(2)));
set(handles.wrist_z_edit,'String', num2str(wr(3)));

end



%########################### ACCEPT BUTTON ################################

function varargout = Accept_Button_Callback(h,~,handles,varargin)
global GHO;
global LHO;
global FL;

okay1=0;
okay2=0; 
okay3=0;
okay4=0; 
okay5=0; 
okay6=0; 


% #################GENERAL INFORMATION#####################################
subjectname = get(handles.subjectname_edit,  'String');
handsides    = get(handles.handside_popup, 'String');
handside     = handsides{get(handles.handside_popup,'Value')};

sl(1)=str2double(get(handles.sensor_lengthI_edit,  'String'));
sl(2)=str2double(get(handles.sensor_lengthII_edit, 'String'));
sl(3)=str2double(get(handles.sensor_lengthIII_edit,'String'));
sl(4)=str2double(get(handles.sensor_lengthIV_edit, 'String'));
sl(5)=str2double(get(handles.sensor_lengthV_edit,  'String'));

if ischar(subjectname) && ischar(handside) && sum(isnan(sl))==0
    okay1=1;
end

% ###################CHECK FOR FINGER DIMENSIONS ##########################
rF(1)=str2double(get(handles.rFI_edit,  'String'));
rF(2)=str2double(get(handles.rFII_edit, 'String'));
rF(3)=str2double(get(handles.rFIII_edit,'String'));
rF(4)=str2double(get(handles.rFIV_edit, 'String'));
rF(5)=str2double(get(handles.rFV_edit,  'String'));

ab(1)=str2double(get(handles.ABI_edit,  'String'));
ab(2)=str2double(get(handles.ABII_edit, 'String'));
ab(3)=str2double(get(handles.ABIII_edit,'String'));
ab(4)=str2double(get(handles.ABIV_edit, 'String'));
ab(5)=str2double(get(handles.ABV_edit,  'String'));

bc(1)=str2double(get(handles.BCI_edit,  'String'));
bc(2)=str2double(get(handles.BCII_edit, 'String'));
bc(3)=str2double(get(handles.BCIII_edit,'String'));
bc(4)=str2double(get(handles.BCIV_edit, 'String'));
bc(5)=str2double(get(handles.BCV_edit,  'String'));

ct(1)=str2double(get(handles.CTI_edit,  'String'));
ct(2)=str2double(get(handles.CTII_edit, 'String'));
ct(3)=str2double(get(handles.CTIII_edit,'String'));
ct(4)=str2double(get(handles.CTIV_edit, 'String'));
ct(5)=str2double(get(handles.CTV_edit,  'String'));

if  ~isnan(rF(1)) && ~isnan(rF(2)) && ~isnan(rF(3)) && ~isnan(rF(4)) && ~isnan(rF(5))  && ...% if a field is empty, the read out of the editor returns NaNs. This means NaNs represent empty editors.
    ~isnan(ab(1)) && ~isnan(ab(2)) && ~isnan(ab(3)) && ~isnan(ab(4)) && ~isnan(ab(5))  && ...
    ~isnan(bc(1)) && ~isnan(bc(2)) && ~isnan(bc(3)) && ~isnan(bc(4)) && ~isnan(bc(5))  && ...
    ~isnan(ct(1)) && ~isnan(ct(2)) && ~isnan(ct(3)) && ~isnan(ct(4)) && ~isnan(ct(5))

    okay2=1;
else
    disp('The finger dimensions are only accepted if all editor fields are defined. Fix this problem or press "Cancel".');
end

if  isnumeric(rF(:)) && isnumeric(ab(:)) && isnumeric(bc(:)) && isnumeric(ct(:))
    okay3=1;
else
    disp('The finger dimensions have to be numeric. Fix this problem or press "Cancel".');
end

% ################CHECK FOR SHOULDER JOINT POSITION########################

sx=str2double(get(handles.shoulder_x_edit,  'String'));
sy=str2double(get(handles.shoulder_y_edit,  'String'));
sz=str2double(get(handles.shoulder_z_edit,  'String'));

wx=str2double(get(handles.wrist_x_edit, 'String'));
wy=str2double(get(handles.wrist_y_edit, 'String'));
wz=str2double(get(handles.wrist_z_edit, 'String')); 

al1=str2double(get(handles.arm_length1_edit,  'String'));
al2=str2double(get(handles.arm_length2_edit,  'String'));
al3=str2double(get(handles.arm_length3_edit,  'String'));

if  isnumeric(sx)  && isnumeric(sy)  && isnumeric(sz) && ...
    isnumeric(wx)  && isnumeric(wy)  && isnumeric(wz) && ...
    isnumeric(al1) && isnumeric(al2) && isnumeric(al3) && ...
    ~isnan(sx)  && ~isnan(sy)  && ~isnan(sz) && ...
    ~isnan(wx)  && ~isnan(wy)  && ~isnan(wz) && ...
    ~isnan(al1) && ~isnan(al2) && ~isnan(al3)
    
    okay4=1;
else
    disp('The shoulder/wrist joint dimensions have to be numeric. Fix this problem or press "Cancel".');
end




% ###################CHECK FOR SENSOR IDENTIFIER ##########################
toollist=cell(8,1);
toollist{1}=get(handles.P1_C1_tool_edit,'String');
toollist{2}=get(handles.P1_C2_tool_edit,'String');
toollist{3}=get(handles.P2_C1_tool_edit,'String');
toollist{4}=get(handles.P2_C2_tool_edit,'String');
toollist{5}=get(handles.P3_C1_tool_edit,'String');
toollist{6}=get(handles.P3_C2_tool_edit,'String');
toollist{7}=get(handles.P4_C1_tool_edit,'String');
toollist{8}=get(handles.P4_C2_tool_edit,'String');


handlelist{1}=get(handles.P1_C1_handle_edit,'String');
handlelist{2}=get(handles.P1_C2_handle_edit,'String');
handlelist{3}=get(handles.P2_C1_handle_edit,'String');
handlelist{4}=get(handles.P2_C2_handle_edit,'String');
handlelist{5}=get(handles.P3_C1_handle_edit,'String');
handlelist{6}=get(handles.P3_C2_handle_edit,'String');
handlelist{7}=get(handles.P4_C1_handle_edit,'String');
handlelist{8}=get(handles.P4_C2_handle_edit,'String');                     
handlelist_cmp={'0A','0B','0C','0D','0E','0F','10','11'};                  % this are the port of the WAVE/Aurora System

sensoridentifier=[];
for ll=1:8                                                                 % the handlelist_cmp represents the order, the handles are provided by the tracking system when data is sent
    for tt=1:8                                                             % the handlelist represents the order, the handles are connected to the tool ports
        if strcmp(handlelist_cmp{ll},handlelist{tt});                      % when the handlelist_cmp is equal the handlelist, we know the id the handle is sent by the system (lets call it send-id)
                thistool=toollist{tt};                                     % get the name of the tool
                if ~isempty(thistool)
                    switch thistool                                        % get the id of this tool
                        case 'Sensor Reference'
                            sensoridentifier(ll)=8;                        % assign the tool id of the tool to the send-id
                        case 'Sensor Thumb'
                            sensoridentifier(ll)=1;
                        case 'Sensor Index'
                            sensoridentifier(ll)=2; 
                        case 'Sensor Middle'
                            sensoridentifier(ll)=3;
                        case 'Sensor Ring'
                            sensoridentifier(ll)=4;
                        case 'Sensor Little'
                            sensoridentifier(ll)=5;
                        case 'Sensor Wrist'
                            sensoridentifier(ll)=6;
                    end
                end
        end
    end
end
if isempty(sensoridentifier)
    disp('No finger/hand - sensors have been assigned .');
    sensoridentifier=get(LHO,'sensoridentifier');
elseif ~isempty(sensoridentifier); %check if finger/hand - sensors are assigned to tools
    okay5=1; 
end


% ###################CHECK FOR JOINT POSITIONS ############################
joints=get(LHO,'fingerjoints');
for ii=1:5
    switch ii
        case 1
                mcp(1,1)=str2double(get(handles.AxI_edit,'String'));
                mcp(1,2)=str2double(get(handles.AyI_edit,'String'));
                mcp(1,3)=str2double(get(handles.AzI_edit,'String'));
                joints(1,7,1)=str2double(get(handles.AxI_edit,'String'));
                joints(1,7,2)=str2double(get(handles.AyI_edit,'String'));
                joints(1,7,3)=str2double(get(handles.AzI_edit,'String'));
        case 2
                mcp(2,1)=str2double(get(handles.AxII_edit,'String'));
                mcp(2,2)=str2double(get(handles.AyII_edit,'String'));
                mcp(2,3)=str2double(get(handles.AzII_edit,'String'));
                joints(2,7,1)=str2double(get(handles.AxII_edit,'String'));
                joints(2,7,2)=str2double(get(handles.AyII_edit,'String'));
                joints(2,7,3)=str2double(get(handles.AzII_edit,'String'));
        case 3
                mcp(3,1)=str2double(get(handles.AxIII_edit,'String'));
                mcp(3,2)=str2double(get(handles.AyIII_edit,'String'));
                mcp(3,3)=str2double(get(handles.AzIII_edit,'String'));
                joints(3,7,1)=str2double(get(handles.AxIII_edit,'String'));
                joints(3,7,2)=str2double(get(handles.AyIII_edit,'String'));
                joints(3,7,3)=str2double(get(handles.AzIII_edit,'String'));
        case 4
                mcp(4,1)=str2double(get(handles.AxIV_edit,'String'));
                mcp(4,2)=str2double(get(handles.AyIV_edit,'String'));
                mcp(4,3)=str2double(get(handles.AzIV_edit,'String'));
                joints(4,7,1)=str2double(get(handles.AxIV_edit,'String'));
                joints(4,7,2)=str2double(get(handles.AyIV_edit,'String'));
                joints(4,7,3)=str2double(get(handles.AzIV_edit,'String'));
        case 5
                mcp(5,1)=str2double(get(handles.AxV_edit,'String'));
                mcp(5,2)=str2double(get(handles.AyV_edit,'String'));
                mcp(5,3)=str2double(get(handles.AzV_edit,'String'));
                joints(5,7,1)=str2double(get(handles.AxV_edit,'String'));
                joints(5,7,2)=str2double(get(handles.AyV_edit,'String'));
                joints(5,7,3)=str2double(get(handles.AzV_edit,'String'));
    end
end

if isnumeric(mcp) % check for correct type
    okay6=1;
else
    disp('The joint positions have to be numeric. Fix this problem or press "Cancel".');
end


fingeridf=sensoridentifier(sensoridentifier<=5); % get only finger sensors of sensoridentifer vector
check=zeros(size(fingeridf)); % matrix to write check results for each finger of sensoridentifier

for ff=1:length(fingeridf)
    ss=fingeridf(ff);
    if ~isnan(mcp(ss,1)) && ~isnan(mcp(ss,2)) && ~isnan(mcp(ss,3)) % if a sensor of the sensoridentifier vector is set correct 
        check(ff)=1;
    end
end
if sum(check)==length(fingeridf) % if all sensors written down in the sensoridentifier are set correctly
    jointsposok=1;  % flag for corretly set jointpositions  
else jointsposok=0;
%      updatehistory(handles.history_listbox,'The metacarpophalangeal joint positions have not been set for the selected finger sensors.  You can "Calibrate" to find the joint positions in 3D space.');
     disp('The metacarpophalangeal joint positions have not been set for the selected finger sensors.  You can "Calibrate" to find the joint positions in 3D space.');
end


fingerdimok=0;
if okay1 && okay2 && okay3 && okay4 && okay6% parameters for finger dimensions
    fingerdimok=1; % flag for correctly set fingerdimension
end




% ####################### SET GLOBALS ####################################
if fingerdimok % finger dimensions and joint positions set correctly
    LHO=set(LHO,'sensoridentifier',sensoridentifier);
    GHO=set(GHO,'sensoridentifier',sensoridentifier);
    LHO=set(LHO,'subjectname',subjectname);
    GHO=set(GHO,'subjectname',subjectname);
    LHO=set(LHO,'handside',handside);
    GHO=set(GHO,'handside',handside);
    LHO=set(LHO,'fingerradius',rF);
    GHO=set(GHO,'fingerradius',rF);
    LHO=set(LHO,'lengthab',ab);
    GHO=set(GHO,'lengthab',bc);
    LHO=set(LHO,'lengthbc',bc);
    GHO=set(GHO,'lengthbc',bc);
    LHO=set(LHO,'lengthct',ct);
    GHO=set(GHO,'lengthct',ct);
    LHO=set(LHO,'lengthdorsum',al1);
    GHO=set(GHO,'lengthdorsum',al1);
    LHO=set(LHO,'lengthlowerarm',al2);
    GHO=set(GHO,'lengthlowerarm',al2);
    LHO=set(LHO,'lengthupperarm',al3);
    GHO=set(GHO,'lengthupperarm',al3);
    LHO=set(LHO,'lengthsensor',sl);
    GHO=set(GHO,'lengthsensor',sl);
    LHO=set(LHO,'metacarpaljoints',mcp);
    GHO=set(GHO,'metacarpaljoints',mcp);
    LHO=set(LHO,'fingerjoints',joints);
    GHO=set(GHO,'fingerjoints',joints);
    GHO=set(GHO,'shoulder',[sx sy sz]);
    
    aj = LHO.armjoints;
    aj(1,1:3)=[wx wy wz];
    LHO.armjoints=aj;
    % Old way, did not replace wrist parameters, why?
    %LHO = determinewrist(LHO,'keep');
    LHO = determinewrist(LHO,'replace');
        
    % Important: wrist is calculated from other parameters so update the GUI!
    wr=get(LHO,'armjoints'); wr=wr(1,1:3);
    disp(wr);
    set(handles.wrist_x_edit,'String', num2str(wr(1)));
    set(handles.wrist_y_edit,'String', num2str(wr(2)));
    set(handles.wrist_z_edit,'String', num2str(wr(3)));
    
    if fingerdimok && jointsposok 
        FL.handloadedfull=1; % set global flags
        FL.handloadedpart=1;
    elseif fingerdimok && ~jointsposok
        FL.handloadedpart=1;
        FL.handloadedfull=0;
    else
        FL.handloadedpart=0;
        FL.handloadedfull=0;
    end
    
    
    h = findall(0,'tag','KinemaTracks');
    handlesMain = guihandles(h);
    set(handlesMain.axes_hand,'UserData',-1);
%     plotHand(LHO,GHO,handlesMain);  
%     
%     h = findall(0,'Name','Hand Settings');
%     delete(h);
    
end

% h1 = findall(0,'Tag','axes_hand');
% axes(h1);
% axis off;
% h2 = findall(0,'Tag','axes_global');
% axes(h2);
% axis off;

mainhandle=findall(0,'Name','KinemaTracks');
handles=guihandles(mainhandle);
% % automaticscale(handles,LHO,GHO);
refreshselectivity(FL,handles); % update GUI, enable new features available through ROM-settings

disp('Hand settings changed');

end

function varargout = Cancel_Button_Callback(h,~,handles,varargin)

h = findall(0,'Name','Hand Settings');
delete(h);

end

function varargout = P1_C1_Button_Callback(h,~,handles,varargin)
arrow=get(handles.P1_C1_button,'String');
switch arrow
    case '->'                                                              % move from listbox to tool  
    sensorvalue=get(handles.availablesensors_listbox,'Value');             % get sensorlist of listbox
    values=get(handles.availablesensors_listbox,'String');                 % get the selected value
    sensor=values{sensorvalue};                                            % get the name of selected sensor
    set(handles.P1_C1_tool_edit,'String',sensor);                          % write the name to sensors edit box
    set(handles.P1_C1_button,'String','<-');                               % change the arrow of the assing button
    values_new=[values(1:sensorvalue-1);values(sensorvalue+1:end)];        % delete the line of the assinged sensor...
    set(handles.availablesensors_listbox,'Value',1);                       % first element is always the selected element
    set(handles.availablesensors_listbox,'String',values_new);             % ... and update the listbox

    case '<-'                                                              % move from tool to listbox
    sensor=get(handles.P1_C1_tool_edit,'String');                          % get sensor name
    values=get(handles.availablesensors_listbox,'String');                 % get the listbox ...
    values{end+1}=sensor;                                                  % ... and add the sensor name
    set(handles.P1_C1_tool_edit,'String',[]);                              % delete the sensor name from tool
    set(handles.P1_C1_button,'String','->');                               % change button arrow to other direction
    set(handles.availablesensors_listbox,'String',values);                 % refresh the new listbox including the new sensor name
    
end
end

function varargout = P1_C2_Button_Callback(h,~,handles,varargin)
arrow=get(handles.P1_C2_button,'String');
switch arrow
    case '->'                                                              % move from listbox to tool  
    sensorvalue=get(handles.availablesensors_listbox,'Value');             % get sensorlist of listbox
    values=get(handles.availablesensors_listbox,'String');                 % get the selected value
    sensor=values{sensorvalue};                                            % get the name of selected sensor
    set(handles.P1_C2_tool_edit,'String',sensor);                          % write the name to sensors edit box
    set(handles.P1_C2_button,'String','<-');                               % change the arrow of the assing button
    values_new=[values(1:sensorvalue-1);values(sensorvalue+1:end)];        % delete the line of the assinged sensor...
    set(handles.availablesensors_listbox,'Value',1);                       % first element is always the selected element
    set(handles.availablesensors_listbox,'String',values_new);             % ... and update the listbox

    case '<-'                                                              % move from tool to listbox
    sensor=get(handles.P1_C2_tool_edit,'String');                          % get sensor name
    values=get(handles.availablesensors_listbox,'String');                 % get the listbox ...
    values{end+1}=sensor;                                                  % ... and add the sensor name
    set(handles.P1_C2_tool_edit,'String',[]);                              % delete the sensor name from tool
    set(handles.P1_C2_button,'String','->');                               % change button arrow to other direction
    set(handles.availablesensors_listbox,'String',values);                 % refresh the new listbox including the new sensor name
    
end
end

function varargout = P2_C1_Button_Callback(h,~,handles,varargin)
arrow=get(handles.P2_C1_button,'String');
switch arrow
    case '->'                                                              % move from listbox to tool  
    sensorvalue=get(handles.availablesensors_listbox,'Value');             % get sensorlist of listbox
    values=get(handles.availablesensors_listbox,'String');                 % get the selected value
    sensor=values{sensorvalue};                                            % get the name of selected sensor
    set(handles.P2_C1_tool_edit,'String',sensor);                          % write the name to sensors edit box
    set(handles.P2_C1_button,'String','<-');                               % change the arrow of the assing button
    values_new=[values(1:sensorvalue-1);values(sensorvalue+1:end)];        % delete the line of the assinged sensor...
    set(handles.availablesensors_listbox,'Value',1);                       % first element is always the selected element
    set(handles.availablesensors_listbox,'String',values_new);             % ... and update the listbox

    case '<-'                                                              % move from tool to listbox
    sensor=get(handles.P2_C1_tool_edit,'String');                          % get sensor name
    values=get(handles.availablesensors_listbox,'String');                 % get the listbox ...
    values{end+1}=sensor;                                                  % ... and add the sensor name
    set(handles.P2_C1_tool_edit,'String',[]);                              % delete the sensor name from tool
    set(handles.P2_C1_button,'String','->');                               % change button arrow to other direction
    set(handles.availablesensors_listbox,'String',values);                 % refresh the new listbox including the new sensor name
    
end
end

function varargout = P2_C2_Button_Callback(h,~,handles,varargin)
arrow=get(handles.P2_C2_button,'String');
switch arrow
    case '->'                                                              % move from listbox to tool  
    sensorvalue=get(handles.availablesensors_listbox,'Value');             % get sensorlist of listbox
    values=get(handles.availablesensors_listbox,'String');                 % get the selected value
    sensor=values{sensorvalue};                                            % get the name of selected sensor
    set(handles.P2_C2_tool_edit,'String',sensor);                          % write the name to sensors edit box
    set(handles.P2_C2_button,'String','<-');                               % change the arrow of the assing button
    values_new=[values(1:sensorvalue-1);values(sensorvalue+1:end)];        % delete the line of the assinged sensor...
    set(handles.availablesensors_listbox,'Value',1);                       % first element is always the selected element
    set(handles.availablesensors_listbox,'String',values_new);             % ... and update the listbox

    case '<-'                                                              % move from tool to listbox
    sensor=get(handles.P2_C2_tool_edit,'String');                          % get sensor name
    values=get(handles.availablesensors_listbox,'String');                 % get the listbox ...
    values{end+1}=sensor;                                                  % ... and add the sensor name
    set(handles.P2_C2_tool_edit,'String',[]);                              % delete the sensor name from tool
    set(handles.P2_C2_button,'String','->');                               % change button arrow to other direction
    set(handles.availablesensors_listbox,'String',values);                 % refresh the new listbox including the new sensor name
    
end
end

function varargout = P3_C1_Button_Callback(h,~,handles,varargin)
arrow=get(handles.P3_C1_button,'String');
switch arrow
    case '->'                                                              % move from listbox to tool  
    sensorvalue=get(handles.availablesensors_listbox,'Value');             % get sensorlist of listbox
    values=get(handles.availablesensors_listbox,'String');                 % get the selected value
    sensor=values{sensorvalue};                                            % get the name of selected sensor
    set(handles.P3_C1_tool_edit,'String',sensor);                          % write the name to sensors edit box
    set(handles.P3_C1_button,'String','<-');                               % change the arrow of the assing button
    values_new=[values(1:sensorvalue-1);values(sensorvalue+1:end)];        % delete the line of the assinged sensor...
    set(handles.availablesensors_listbox,'Value',1);                       % first element is always the selected element
    set(handles.availablesensors_listbox,'String',values_new);             % ... and update the listbox

    case '<-'                                                              % move from tool to listbox
    sensor=get(handles.P3_C1_tool_edit,'String');                          % get sensor name
    values=get(handles.availablesensors_listbox,'String');                 % get the listbox ...
    values{end+1}=sensor;                                                  % ... and add the sensor name
    set(handles.P3_C1_tool_edit,'String',[]);                              % delete the sensor name from tool
    set(handles.P3_C1_button,'String','->');                               % change button arrow to other direction
    set(handles.availablesensors_listbox,'String',values);                 % refresh the new listbox including the new sensor name
    
end
end

function varargout = P3_C2_Button_Callback(h,~,handles,varargin)
arrow=get(handles.P3_C2_button,'String');
switch arrow
    case '->'                                                              % move from listbox to tool  
    sensorvalue=get(handles.availablesensors_listbox,'Value');             % get sensorlist of listbox
    values=get(handles.availablesensors_listbox,'String');                 % get the selected value
    sensor=values{sensorvalue};                                            % get the name of selected sensor
    set(handles.P3_C2_tool_edit,'String',sensor);                          % write the name to sensors edit box
    set(handles.P3_C2_button,'String','<-');                               % change the arrow of the assing button
    values_new=[values(1:sensorvalue-1);values(sensorvalue+1:end)];        % delete the line of the assinged sensor...
    set(handles.availablesensors_listbox,'Value',1);                       % first element is always the selected element
    set(handles.availablesensors_listbox,'String',values_new);             % ... and update the listbox

    case '<-'                                                              % move from tool to listbox
    sensor=get(handles.P3_C2_tool_edit,'String');                          % get sensor name
    values=get(handles.availablesensors_listbox,'String');                 % get the listbox ...
    values{end+1}=sensor;                                                  % ... and add the sensor name
    set(handles.P3_C2_tool_edit,'String',[]);                              % delete the sensor name from tool
    set(handles.P3_C2_button,'String','->');                               % change button arrow to other direction
    set(handles.availablesensors_listbox,'String',values);                 % refresh the new listbox including the new sensor name
    
end
end

function varargout = P4_C1_Button_Callback(h,~,handles,varargin)
arrow=get(handles.P4_C1_button,'String');
switch arrow
    case '->'                                                              % move from listbox to tool  
    sensorvalue=get(handles.availablesensors_listbox,'Value');             % get sensorlist of listbox
    values=get(handles.availablesensors_listbox,'String');                 % get the selected value
    sensor=values{sensorvalue};                                            % get the name of selected sensor
    set(handles.P4_C1_tool_edit,'String',sensor);                          % write the name to sensors edit box
    set(handles.P4_C1_button,'String','<-');                               % change the arrow of the assing button
    values_new=[values(1:sensorvalue-1);values(sensorvalue+1:end)];        % delete the line of the assinged sensor...
    set(handles.availablesensors_listbox,'Value',1);                       % first element is always the selected element
    set(handles.availablesensors_listbox,'String',values_new);             % ... and update the listbox

    case '<-'                                                              % move from tool to listbox
    sensor=get(handles.P4_C1_tool_edit,'String');                          % get sensor name
    values=get(handles.availablesensors_listbox,'String');                 % get the listbox ...
    values{end+1}=sensor;                                                  % ... and add the sensor name
    set(handles.P4_C1_tool_edit,'String',[]);                              % delete the sensor name from tool
    set(handles.P4_C1_button,'String','->');                               % change button arrow to other direction
    set(handles.availablesensors_listbox,'String',values);                 % refresh the new listbox including the new sensor name
    
end
end

function varargout = P4_C2_Button_Callback(h,~,handles,varargin)
arrow=get(handles.P4_C2_button,'String');
switch arrow
    case '->'                                                              % move from listbox to tool  
    sensorvalue=get(handles.availablesensors_listbox,'Value');             % get sensorlist of listbox
    values=get(handles.availablesensors_listbox,'String');                 % get the selected value
    sensor=values{sensorvalue};                                            % get the name of selected sensor
    set(handles.P4_C2_tool_edit,'String',sensor);                          % write the name to sensors edit box
    set(handles.P4_C2_button,'String','<-');                               % change the arrow of the assing button
    values_new=[values(1:sensorvalue-1);values(sensorvalue+1:end)];        % delete the line of the assinged sensor...
    set(handles.availablesensors_listbox,'Value',1);                       % first element is always the selected element
    set(handles.availablesensors_listbox,'String',values_new);             % ... and update the listbox

    case '<-'                                                              % move from tool to listbox
    sensor=get(handles.P4_C2_tool_edit,'String');                          % get sensor name
    values=get(handles.availablesensors_listbox,'String');                 % get the listbox ...
    values{end+1}=sensor;                                                  % ... and add the sensor name
    set(handles.P4_C2_tool_edit,'String',[]);                              % delete the sensor name from tool
    set(handles.P4_C2_button,'String','->');                               % change button arrow to other direction
    set(handles.availablesensors_listbox,'String',values);                 % refresh the new listbox including the new sensor name
    
end
end

