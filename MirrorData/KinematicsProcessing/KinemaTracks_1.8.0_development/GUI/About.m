function h = About(varargin)


if nargin == 0  % LAUNCH GUI
    
    %check if figure already exists
    h = findall(0,'tag','About');
    
    if (isempty(h))
        %Launch the figure
        fig = openfig(mfilename,'reuse');
        set(fig,'NumberTitle','off', 'Tag' ,'About');
        set(fig,'NumberTitle','off', 'Name','About');
        
    else % when the figure has already been opend, bring it to front.
        
        %Figure exists ==> error
        disp('Not allowed to start multiple Windows. Window is already open.');
        %bring figure to front
        figure(h);
        return
        
    end;
    
end %end of KinemaTracks




