%##########################  REFRESH  GUI  ################################

function [handles] = refreshselectivity(FL,handles)

if     FL.comfound==0
    thiscase=1; % ready for nothing, system not found/enabled or wrong com-port
elseif FL.comfound==1 && FL.romset==0;
    thiscase=2; % ready for system init
elseif FL.comfound==1 && FL.romset==1 && FL.sysinit==1 && FL.toolsinit==0
    thiscase=3; % ready for tool init
elseif FL.comfound==1 && FL.romset==1 && FL.sysinit==1 && FL.toolsinit==1 && FL.handloadedpart==1 && FL.handloadedfull==0
    thiscase=4; % ready for calibration
elseif FL.comfound==1 && FL.romset==1 && FL.sysinit==1 && FL.toolsinit==1 && FL.handloadedpart==1 && FL.handloadedfull==1
    thiscase=5; % ready for tracking
else
    thiscase=6;
end



switch thiscase
    case 1 % case 1
        sl = {'off',[0.941 0.941 0.941], 'off',[0.941 0.941 0.941], 'off', 'off','off','off','off','off' ...
              'off','off','off','off','off','off','off','on','','', ...
              '','','','','on' ,'off','off','off','off','on' ...
              'on' ,'on','on','','','','','','','on', ...
              'on','off','on','on','on','on','off','','','' ...
              '','','','','off','off','off','off','off','', ...
              '','','','','on','on','on','on','on','on', ...
              'on','','','','','','','','',''};
        makechange=1;
          
    case 2
        sl = {'on',[0.941 0.941 0.941], 'off',[0.941 0.941 0.941], 'off', 'off','off','off','off','off' ...
              'off','off','off','off','off','off','off','on','','', ...
              '','','','','on' ,'on','on','off','off','on' ...
              'on' ,'on','on','','','','','','','on', ...
              'on','off','on','on','on','on','on','','','' ...
              '','','','','on','on','on','off','off','', ...
              '','','','','on','on','on','on','on','on', ...
              'on','','','','','','','','',''};
        makechange=1;
        
    case 3 % case 3
        sl = {'on',[0.941 0.941 0.941], 'on',[0.941 0.941 0.941], 'off', 'off','off','off','off','off' ...
              'off','off','off','off','off','off','off','on','','', ...
              '','','','','on' ,'on','on','off','off','on' ...
              'on' ,'on','on','','','','','','','on', ...
              'on' ,'on','on','on','on','on','on','','','' ...
              '','','','','on','on','on','on','off','', ...
              '','','','','on','on','on','on','on','on', ...
              'on','','','','','','','','',''};
        makechange=1;
        
    case 4 % case 4
        sl = {'on',[0.941 0.941 0.941], 'on',[0.941 0.941 0.941], 'on', 'off','off','off','off','off' ...
              'off','off','off','off','off','off','off','on','','', ...
              '','','','','on' ,'on','on','off','off','on' ...
              'on' ,'on','on','','','','','','','on', ...
              'on' ,'on','on','on','on','on','on','','','' ...
              '','','','','on','on','on','on','off','', ...
              '','','','','on','on','on','on','on','on', ...
              'on','','','','','','','','',''};
        makechange=1;

    case 5 % case 5
    sl = {'on',[0.941 0.941 0.941], 'on',[0.941 0.941 0.941], 'on', 'on','off','off','off','on' ...
          'off','on','on','on','on','off','off','on','','', ...
          '','','','','on' ,'on','on','off','off','on' ...
          'on' ,'on','on','','','','','','','on', ...
          'on' ,'on','on','on','on','on','on','','','' ...
          '','','','','on','on','on','on','off','', ...
          '','','','','on','on','on','on','on','on', ...
          'on','','','','','','','','',''};
       makechange=1;
    otherwise
        makechange=0; %change nothing if no case is fullfilled
        
end

      
if makechange     
    % GUI
    set(handles.initialize_system_button,'Enable',sl{1});
    set(handles.initialize_system_button,'BackgroundColor',sl{2});
    set(handles.initialize_tools_button,'Enable',sl{3});
    set(handles.initialize_tools_button,'BackgroundColor',sl{4});
    set(handles.calibrate_button,'Enable',sl{5});
    set(handles.start_toggle,'Enable',sl{6});
    set(handles.record_button,'Enable',sl{7});
    set(handles.sample_rate_text,'Enable',sl{8});
    set(handles.sample_rate_edit,'Enable',sl{9});
%    set(handles.plot_enable_checkbox,'Enable',sl{10});
%    set(handles.udp_enable_checkbox,'Enable',sl{11});
%   set(handles.cerebus_enable_checkbox,'Enable',sl{12});
%   set(handles.save_enable_checkbox,'Enable',sl{13});
    set(handles.decimation_text,'Enable',sl{14});
    set(handles.decimation_edit,'Enable',sl{15});
    set(handles.history_listbox,'Enable',sl{18});

    % FILE
    set(handles.file_menue,'Enable',sl{25});
    set(handles.save_project_menue,'Enable',sl{26});
    set(handles.save_project_as_menue,'Enable',sl{27});
    set(handles.save_hand_menue,'Enable',sl{28});
    set(handles.save_hand_as_menue,'Enable',sl{29});
    set(handles.load_project_menue,'Enable',sl{30});
    set(handles.load_hand_menue,'Enable',sl{31});
    set(handles.clipboard_menue,'Enable',sl{32});
    set(handles.exit_menue,'Enable',sl{33});

    % SETTINGS
    set(handles.settings_menue,'Enable',sl{40});
    set(handles.tool_menue,'Enable',sl{41});
    set(handles.volume_menue,'Enable',sl{42});
    set(handles.com_menue,'Enable',sl{43});
    set(handles.udp_menue,'Enable',sl{44});
    set(handles.cerebus_menu,'Enable',sl{45});
    set(handles.plot_menue,'Enable',sl{46});
    set(handles.save_menue,'Enable',sl{47});

    % SYSTEM
    set(handles.system_menue,'Enable',sl{55});
    set(handles.reset_menue,'Enable', sl{56});
    set(handles.initialize_system_menue,'Enable',sl{57});
    set(handles.initialize_tools_menue,'Enable',sl{58});
    set(handles.information_menue,'Enable',sl{59});

    % HELP
    set(handles.help_menue,'Enable',sl{65});
    set(handles.manual_kinematracks_menue,'Enable',sl{66});
    set(handles.ndi_user_guide_aurora_menue,'Enable',sl{67});
    set(handles.ndi_user_guide_wave_menue,'Enable',sl{68});
    set(handles.ndi_api_guide_menue,'Enable',sl{69});
    set(handles.ndi_tool_design_guide_menue,'Enable',sl{70});
    set(handles.ndi_6darchitect_guide_menue,'Enable',sl{71});
end


% some additional simple cases
if FL.handloadedpart==1 % if a hand is set up correctly, allow to save it
    set(handles.save_hand_menue,'Enable','on');
    set(handles.save_hand_as_menue,'Enable','on');  
end

if FL.handloadedpart==1
    set(handles.player_menue,'Enable','on');
    set(handles.extract_menue,'Enable','on');
else
    set(handles.player_menue,'Enable','off');
    set(handles.extract_menue,'Enable','off');
end
    

if FL.udpok
    set(handles.udp_enable_checkbox,'Enable','on');
end

if FL.trackingon
    set(handles.decimation_edit,'Enable','off');
    set(handles.decimation_text,'Enable','off');
end

if FL.trackingon && FL.cerebusok
    set(handles.record_button,'Enable','on');
end


