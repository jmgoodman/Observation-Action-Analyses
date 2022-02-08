function []=plotHand(LHO,GHO,handles)

global myh1; % finger local
global myh2; % finger global
global myh3; % wrist help vector local
global myh4; % wrist help vector global
global myh5; % elbo help vector global

fingerjoints=LHO.fingerjoints;
gfingerjoints=GHO.fingerjoints;
garmjoints=GHO.armjoints;
larmjoints=LHO.armjoints;

shoulder=GHO.shoulder;
numJoints=size(fingerjoints,1);
 % USER DATA -1 reset , 0, first start, 1:just update figure
 mission = get(handles.axes_hand,'UserData');
if isempty(mission) || mission==0 || mission==-1
        
        cp1 = get(handles.axes_hand,'CameraPosition'); % save cameraposition for mission -1 (refresh/update)
        cp2 = get(handles.axes_global,'CameraPosition');
        
        cla(handles.axes_hand);
        cla(handles.axes_global);
    
        
        % CALCULATE AUTO SCALE:
        % find the longest finger:
        ab=LHO.lengthab;
        bc=LHO.lengthbc;
        ct=LHO.lengthct;
        if numel(ab)==numel(bc) && numel(bc)==numel(ct) % check if all fingers have the same amount of elemtents
            numFing=numel(ab); 
            thisfingerlength=zeros(1,numFing);
            for ii=1:numel(ab)
                thisfingerlength(ii)=ab(ii)+bc(ii)+ct(ii);
            end
            fingerlength=max(thisfingerlength);
        else
            error('Finger not set correctly');
        end
        %find extrem values of fingerjoints
        metacarpaljoints=LHO.metacarpaljoints;
        xminMCP=min(metacarpaljoints(:,1));
        xmaxMCP=max(metacarpaljoints(:,1));
        zmaxMCP=max(metacarpaljoints(:,3));
        
        XLimMin = xminMCP-fingerlength;
        XLimMax = xmaxMCP+fingerlength; 
        YLimMin = 0-fingerlength/2;
        YLimMax = 0+fingerlength;
        ZLimMin = 0-1.5*fingerlength;
        ZLimMax = zmaxMCP+1.5*fingerlength;
        
        
        
        % CREATE FIRST PLOT
        color=['w','r','b','g','m','c'];
        
        for ff=1:numJoints   
          myh1(ff)=plot3(handles.axes_hand, ...
               [fingerjoints(ff,7,1),fingerjoints(ff,6,1),fingerjoints(ff,5,1),fingerjoints(ff,4,1)], ...
               [fingerjoints(ff,7,2),fingerjoints(ff,6,2),fingerjoints(ff,5,2),fingerjoints(ff,4,2)], ...
               [fingerjoints(ff,7,3),fingerjoints(ff,6,3),fingerjoints(ff,5,3),fingerjoints(ff,4,3)], ...
               'LineWidth',4,'Color',color(ff));
          hold(handles.axes_hand,'on')
        end
                
        % get wrist position in local hand coordinates
       
        wrist=larmjoints(1,1:3);
        wrist_h=larmjoints(5,1:3);
        
        xax = [wrist(1)-5 wrist(1)+5];
        yax = [wrist(2)-5 wrist(2)+5];
        zax = [wrist(3)-5 wrist(3)+5];
        
        plot3(handles.axes_hand,[xax(1),xax(2)],[wrist(2), wrist(2)],[ wrist(3),wrist(3)],'Color','r','LineWidth',1);
        plot3(handles.axes_hand,[wrist(1),wrist(1)],[yax(1), yax(2)],[ wrist(3),wrist(3)],'Color','b','LineWidth',1);
        plot3(handles.axes_hand,[wrist(1),wrist(1)],[wrist(2), wrist(2)],[zax(1),zax(2)],'Color','g','LineWidth',1);
        
        % help vector wrist local
        myh3=plot3(handles.axes_hand,[wrist(1) wrist_h(1)],[wrist(2) wrist_h(2)],[wrist(3) wrist_h(3)],'Color','r','LineWidth',0.5);
        
        
        
        % reference sensor axis
        plot3(handles.axes_hand,[-5 5],[0 0],[0 0],'Color','r','LineWidth',1);
        plot3(handles.axes_hand,[0 0 ],[-5 5],[0 0],'Color','b','LineWidth',1);
        plot3(handles.axes_hand,[0 0],[0 0],[-5 5],'Color','g','LineWidth',1);

        
        
  
        % ADUJST AUTOSCALE
        set(handles.axes_hand,'XGrid','on','YGrid','on','ZGrid','on',...
                'XColor',[0.5,0.5,0.5],'YColor',[0.5,0.5,0.5],'ZColor',[0.5,0.5,0.5],...
                'Box','on','Color','k','DataAspectRatio',[1,1,1],'View',[40.5 18]);
            
%                             'XLim',[XLimMin XLimMax],...
%                 'YLim',[YLimMin YLimMax],...
%                 'ZLim',[ZLimMin ZLimMax],...

        xlabel(handles.axes_hand,'X');
        ylabel(handles.axes_hand,'Y');
        zlabel(handles.axes_hand,'Z');   
        axis on;
        %find extrem values of handjoints
        XLimMin = min(shoulder(1,1)+20,-250);
        XLimMax = max(shoulder(1,1)+20, 250); 
        YLimMin = min(shoulder(1,2)+20,-250);
        YLimMax = max(shoulder(1,2)+20, 250);
        ZLimMin = min(shoulder(1,3)+20,-500);
        ZLimMax = max(shoulder(1,3)+20,   0);
        
        axis on;
        
%##########################################################################
%##########################################################################

        % CREATE FIRST PLOT of global hand
        color=['w','r','b','g','m','c','y'];
        for ff=1:numJoints   
          myh2(ff)=plot3(handles.axes_global, ...
               [garmjoints(1,1),gfingerjoints(ff,7,1),gfingerjoints(ff,6,1),gfingerjoints(ff,5,1),gfingerjoints(ff,4,1)], ...
               [garmjoints(1,2),gfingerjoints(ff,7,2),gfingerjoints(ff,6,2),gfingerjoints(ff,5,2),gfingerjoints(ff,4,2)], ...
               [garmjoints(1,3),gfingerjoints(ff,7,3),gfingerjoints(ff,6,3),gfingerjoints(ff,5,3),gfingerjoints(ff,4,3)], ...
               'LineWidth',4,'Color',color(ff));
        hold(handles.axes_global,'on');
        end

        myh2(numJoints+1) = plot3(handles.axes_global,...
                [shoulder(1,1),garmjoints(2,1),garmjoints(1,1)], ...
                [shoulder(1,2),garmjoints(2,2),garmjoints(1,2)], ...
                [shoulder(1,3),garmjoints(2,3),garmjoints(1,3)], ...
                 'LineWidth',8,'Color',color(6));
             
             
        % get wrist position in local hand coordinates
        wrist=garmjoints(1,1:3);
        wrist_h=garmjoints(5,1:3);
        elbow  =garmjoints(2,1:3);
        elbow_h=garmjoints(4,1:3);
        
        % help vector wrist local
        myh4=plot3(handles.axes_global,[wrist(1) wrist_h(1)],[wrist(2) wrist_h(2)],[wrist(3) wrist_h(3)],'Color','r','LineWidth',0.5);
        myh5=plot3(handles.axes_global,[elbow(1) elbow_h(1)],[elbow(2) elbow_h(2)],[elbow(3) elbow_h(3)],'Color','r','LineWidth',0.5);
        axis on;
%         myh3=plot3(handles.axes_global,[         
                 
%         if mission==-1

                % ADUJST AUTOSCALE
        %         shoulder=get(GHO,'shoulder');
                set(handles.axes_global,'XGrid','off','YGrid','off','ZGrid','off',...
                'XColor',[0.5,0.5,0.5],'YColor',[0.5,0.5,0.5],'ZColor',[0.5,0.5,0.5],...
                'Box','on','Color','k','DataAspectRatio',[1,1,1],'View',[322.5 30],'ZDir','reverse','YDir','reverse');
%                 'XLim',[XLimMin XLimMax],...
%                 'YLim',[YLimMin YLimMax],...
%                 'ZLim',[ZLimMin ZLimMax],...
%         end
        
        set(handles.axes_hand,'CameraPosition',cp1);
        set(handles.axes_global,'CameraPosition',cp2);
%         end
    
        set(handles.axes_hand,'UserData',1); 
        
else 
        for ff=1:numJoints
            %local
            set(myh1(ff),'XData',[fingerjoints(ff,7,1),fingerjoints(ff,6,1),fingerjoints(ff,5,1),fingerjoints(ff,4,1)]);
            set(myh1(ff),'YData',[fingerjoints(ff,7,2),fingerjoints(ff,6,2),fingerjoints(ff,5,2),fingerjoints(ff,4,2)]);
            set(myh1(ff),'ZData',[fingerjoints(ff,7,3),fingerjoints(ff,6,3),fingerjoints(ff,5,3),fingerjoints(ff,4,3)]);
            %global
            set(myh2(ff),'XData',[gfingerjoints(ff,7,1),gfingerjoints(ff,6,1),gfingerjoints(ff,5,1),gfingerjoints(ff,4,1)]);
            set(myh2(ff),'YData',[gfingerjoints(ff,7,2),gfingerjoints(ff,6,2),gfingerjoints(ff,5,2),gfingerjoints(ff,4,2)]);
            set(myh2(ff),'ZData',[gfingerjoints(ff,7,3),gfingerjoints(ff,6,3),gfingerjoints(ff,5,3),gfingerjoints(ff,4,3)]);
        end
        
        set(myh2(numJoints+1),'XData',[shoulder(1,1),garmjoints(2,1),garmjoints(1,1)]);
        set(myh2(numJoints+1),'YData',[shoulder(1,2),garmjoints(2,2),garmjoints(1,2)]);
        set(myh2(numJoints+1),'ZData',[shoulder(1,3),garmjoints(2,3),garmjoints(1,3)]);
        
        
        
        
        wrist=garmjoints(1,1:3);
        wrist_h=garmjoints(5,1:3);
        
        % help vector wrist local
        set(myh4,'XData',[wrist(1) wrist_h(1)]);
        set(myh4,'YData',[wrist(2) wrist_h(2)]);
        set(myh4,'ZData',[wrist(3) wrist_h(3)]);
        
        
        elbow  =garmjoints(2,1:3);
        elbow_h=garmjoints(4,1:3);
        
        % help vector wrist local
        set(myh5,'XData',[elbow(1) elbow_h(1)]);
        set(myh5,'YData',[elbow(2) elbow_h(2)]);
        set(myh5,'ZData',[elbow(3) elbow_h(3)]);
        
        
        
        

end

end

