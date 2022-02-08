 function [data_i time_i] = interpolatekinematic(data,time,sr,maxgap)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     INTERPOLATE KINEMATICS              
%
% DESCRIPTION:
% This function interpolates missing samples of time-continous data, and
% resamples the data if slected.
% 
% HELPFUL INFORMATION:  -Matalab Help, command interp1
%
% SYNTAX:    [data_i] = interpolatekinematic(data,time,sr,maxgap)
%
%        data   ...    data to interpolate, vector or matrix (each row is a
%                      channel)
%        time   ...    time stamps of data
%        sr     ...    new sampling rate, if 0, data will not be resampled
%        maxgap ...    missing samples (gap) of a given size will not be
%                      interpolated, but marked with NANs. 
%
%                      
%                       
% EXAMPLE:   
%
% AUTHOR: ©Stefan Schaffelhofer                                     NOV11 %
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if sr==0
    time_i=time;
else
    tst=time(1);
    tst =round(sr*time(1))/sr;
    tend=time(end); % get maximum time
    tend=round(sr*tend)/sr;
    time_i=tst:1/sr:tend;               % create time vector, that starts at zero, hand tracking often starts a few seconds later as the recording system!
end

numCh=size(data,1);
data_i=nan(numCh,length(time_i));       % create a data matrix, that fits to the time vector that starts at zero

for ii=1:numCh % for channels
    temp=data(ii,:);
    no_nan=not(isnan(temp)); % are there valid samples?
    if sum(no_nan)>=2;
        data_i(ii,:) = interp1(time(not(isnan(temp))),temp(not(isnan(temp))),time_i,'cubic'); % interpolate
        
        % interpolation causes non valid and very large samples at the
        % beginning of a channal, when the signal does not start at zeros.
        % The next two lines detect the first valid sample and sets the
        % invalid samples before to NaN
        firstvalidtime=time(find(~isnan(temp),1,'first'));
        firstvalidsample=find(time_i>=firstvalidtime,1,'first');
        data_i(ii,1:firstvalidsample)=NaN;
        
        nans=find(isnan(data(ii,:)));
        kk=1;
        while kk<length(nans)
            found=0;
            gs=nans(kk);
            while found==0 && kk<=length(nans)
                
                if kk==length(nans)
                    found=1;
                    ge=nans(kk);
                    kk=kk+1;
                else
                    if nans(kk)==nans(kk+1)-1
                        kk=kk+1;
                    else
                        found=1;
                        ge=nans(kk)+1;
                        kk=kk+1;
                    end
                end
            end
            gapstart=time(gs); % gap start in samples (calculated for the new sampling rate)
            gapend  =time(ge); % gap end in samples
            gap     =gapend-gapstart;
            
            if gap>=maxgap  % compare if the gap is greater then the maximam gap size defined by the user
                data_i(ii,find(time_i>=gapstart,1,'first'):find(time_i<=gapend,1,'last'))=NaN;% set interpolated data of gap to nan
            end  
        end
    end
    
    % mark time gaps with NANs, sometimes, the handtracking devices stops
    % working imidiatly or the tracking is stoped. In this cases, the end
    % of such a session has valid values (not NAN). To find the gaps,
    % between two session of a recording, the time gaps between samples are
    % checked as well. To large gaps, here selected to be 1 s, are filled
    % with NANs, to avoid interpolated values that would be inapropriate
    % for such 
    deltat=zeros(1,length(time)-1);
    deltat(:,:)=time(2:end)-time(1:end-1);
    timegaps=find(deltat>=maxgap);
    for aa=1:numel(timegaps)
        gapstart=find(time_i<=time(timegaps(aa)),1,'last'); % gap start in samples (calculated for the new sampling rate)
        gapend  =find(time_i>=time(timegaps(aa)+1),1,'first'); % gap end in samples
        data_i(ii,gapstart:gapend)=nan; % set interpolated data of gap to nan
    end
        
    
end


end % end of function

