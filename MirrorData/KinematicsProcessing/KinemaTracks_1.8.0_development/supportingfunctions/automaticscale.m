function [STO] = automaticscale(handles,LHO,GHO,STO)

metacarpaljoints=get(LHO,'metacarpaljoints');

if ~isempty(LHO.metacarpaljoints)
    
    xminMCP=min(metacarpaljoints(:,1));
    xmaxMCP=max(metacarpaljoints(:,1));
    zmaxMCP=max(metacarpaljoints(:,3));

    ab=get(LHO,'lengthab');
    bc=get(LHO,'lengthbc');
    ct=get(LHO,'lengthct');
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

    XLimMin = xminMCP-fingerlength;
    XLimMax = xmaxMCP+fingerlength; 
    YLimMin = 0-fingerlength/2;
    YLimMax = 0+fingerlength;
    ZLimMin = 0-1.5*fingerlength;
    ZLimMax = zmaxMCP+1.5*fingerlength;

    if ~isnan(XLimMin) && isnan(XLimMax) && ~isnan(YLimMin) && ~isnan(YLimMax) ...
            && ~isnan(ZLimMin) && ~isnan(ZLimMax)
            set(handles.axes_hand,'XGrid','on','YGrid','on','ZGrid','on',...
            'XColor',[0.5,0.5,0.5],'YColor',[0.5,0.5,0.5],'ZColor',[0.5,0.5,0.5],...
            'XLim',[XLimMin XLimMax],...
            'YLim',[YLimMin YLimMax],...
            'ZLim',[ZLimMin ZLimMax],...
            'Box','on','Color','k','DataAspectRatio',[1,1,1]);
    end   
    shoulder=get(GHO,'shoulder');
    
    STO = set(STO,'localhandaxes',[XLimMin XLimMax YLimMin YLimMax ZLimMin ZLimMax]);
    
    %find extrem values of handjoints
    XLimMin = min(shoulder(1,1)+20,-150);
    XLimMax = max(shoulder(1,1)+20, 250); 
    YLimMin = min(shoulder(1,2)+20,-150);
    YLimMax = max(shoulder(1,2)+20, 150);
    ZLimMin = min(-300,-300);
    ZLimMax = max(0,   0);


    % ADUJST AUTOSCALE
    %         shoulder=get(GHO,'shoulder');
    set(handles.axes_global,'XGrid','off','YGrid','off','ZGrid','off',...
    'XColor',[0.5,0.5,0.5],'YColor',[0.5,0.5,0.5],'ZColor',[0.5,0.5,0.5],...
    'XLim',[XLimMin XLimMax],...
    'YLim',[YLimMin YLimMax],...
    'ZLim',[ZLimMin ZLimMax],...
    'Box','on','Color','k','DataAspectRatio',[1,1,1],'ZDir','reverse',...
    'CameraPosition',[ -2.6605   -0.9844   -1.3810]*1000);

    set(handles.axes_hand,'CameraPosition',[  0.3910   -1.2106    0.5022]*1000);
    
    STO = set(STO,'globalhandaxes',[XLimMin XLimMax YLimMin YLimMax ZLimMin ZLimMax]);
    updatehistory(handles.history_listbox,'Autoscale done.');
    
    
else
   updatehistory(handles.history_listbox,'Autoscale not possible. No data availabel.');
    
end