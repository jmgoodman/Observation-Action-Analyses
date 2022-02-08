function [ plotstruct ] = paramter2array(AO,STAT,NO,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  CONVERT PARAMETER TO ARRAY STRUCTURE
% DESCRIPTION: 
%
% This function extracts parameters from a neuronobj (NO) and brings it
% into an array structure, that can be plotted 
%
% The user can choose between different options, that extracts information
% either from single or multiple NO, providing informotion of multiple
% recording session
%
% SYNTAX:    paramter2array(AO,STAT,NO,'group','mixed', ...
%                           'specification','tuned','average','logical');
%            
%                   AO  ... arrayobj
%                 STAT  ... can be a statsobj or a cell, holding multiple
%                           STATSs (eg. {ST1,ST2,ST3,ST4});
%                   NO  ... can be a neuronobj or a cell, holding multiple
%                           NOs (eg. {NO1,NO2,NO3,NO4});
%     specification     ... optional input; spcify, what you want to plot
%                           'tuned',   locate only tuned neurons
%                           'single'   locate single units
%                           'partner'  locate partner neurons
%                           'mirror'   locate mirror neurons
%                           'information' locate information coding of neuron
%                           'visual' locate only visual neurons
%                           'motor' locate only motor neurons
%                           'visuo-motor' locate only visuo-motor neurons
%            
% EXAMPLE:
%           paramter2array(AO,{NO1,NO2},'group','mixed', ...
%                           'specification','tuned','average','logical');
%
%
% Author: Stefan Schaffelhofer                                     JAN 2013
%
%          DO NOT USE THIS CODE WITHOUT AUTHORS PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%check SPKOBJ
if ~isobject(AO)                                          
    error('Wrong input argument: First input argument has to be a ARRAYOBJ.');
else
    if strcmpi(class(AO), 'arrayobj') == 0
        error('Wrong input argument: First input argument has to be a ARRAYOBJ.');
    end
end

if iscell(STAT) % in case multiple neuron objects are forwarded as cell
    for ii=1:length(STAT)
        if ~isobject(STAT{ii})
            error('Wrong input argument: Second input argument has to be a STATOBJ.');
        end
    end
else % in case neuronobject is forwarded as a neuronobj.
    if ~isobject(STAT) || ~strcmpi(class(STAT), 'statobj')
        error('Wrong input argument: Second input argument has to be a STATOBJ.');
    else
        datatemp=STAT;
        STAT=cell(1,1);
        STAT{1,1}=datatemp;
    end
end

if iscell(NO) % in case multiple neuron objects are forwarded as cell
    for ii=1:length(NO)
        if ~isobject(NO{ii})
            error('Wrong input argument: Second input argument has to be a NEURONOBJ.');
        end
    end
else % in case neuronobject is forwarded as a neuronobj.
    if ~isobject(NO) || ~strcmpi(class(NO), 'statobj')
        error('Wrong input argument: Second input argument has to be a NEURONOBJ.');
    else
        datatemp=NO;
        NO=cell(1,1);
        NO{1,1}=datatemp;
    end
end


specificationcheck = 0;
groupcheck         = 0;
maskcheck          = 0;
averagecheck       = 0;


for ii = 1:numel(varargin)
    if strcmpi(varargin{ii}, 'specification')
        specificationid   = ii+1;
        specificationcheck = 1;
    elseif strcmpi(varargin{ii}, 'group')
        groupid       = ii+1;
        groupcheck = 1;
    elseif strcmpi(varargin{ii}, 'mask')
        maskid       = ii+1;
        maskcheck  = 1;
    elseif strcmpi(varargin{ii}, 'average')
        averageid    = ii+1;
        averagecheck = 1;
    end
end


if specificationcheck == 0
    specification='tuned'; % default
else
    specification=varargin{specificationid};
end


switch specification
    case 'tuned'
        %check 'alignment' input
        if groupcheck == 0
            error('Not enough input arguements.');
        else
            group=varargin{groupid};
        end
        
    case 'information'
        if groupcheck == 0
            error('Not enough input arguements.');
        else
            group=varargin{groupid};
        end        
        
    case 'celltype'
        if ischar(varargin{specificationid+1})
            typename={varargin{specificationid+1}};
        else
            typename=varargin{specificationid+1};
        end
            
        %doesn't matter
end



if maskcheck == 0
    mask=''; % default
else
    mask=varargin{maskid};
end

if averagecheck == 0
    average='logic'; % default
else
    average=varargin{averageid};
end

%--------------------------------------------------------------------------

nrrecs = numel(STAT);




%create output cell:

nrArrays=numel(AO.ID);



dimensions = AO.dim;
channelmap = AO.channelmap;


switch specification
    case 'tuned' % locate tuned cells
           % Create a cell array including the data from each epoch and array.
           % Each element of this cell, includes a matrix, holding the information
           % of each electrode across the different recordings (width of electorde x
           % length of electrode x recording) 
           
           
            if isnumeric(group)
                for ii=1:nrrecs
                    N=STAT{ii};
                    if isempty(N.data(1,group))
                        error('Group not available.');
                    end
                end
            else
                group=groupname2groupid(group);  
            end
           
            ep=nan(1,nrrecs);
            for nn=1:nrrecs
                N=STAT{1,nn};
                ep(nn)=size(N.epochs{1,group},2);
                epochs=N.epochs{group};
            end

            if min(ep)~=max(ep)
                error('Data sets have different number of epochs.');
            else
                nrEpochs=min(ep);
            end

 

            BAS=cell(nrEpochs,nrArrays); % create basis array
            
            % find the most cells detected on a channel on all arrays and
            % recordings. this info is used for allocation of memory.
            
            for aa=1:nrArrays
                dim=dimensions{aa};
                map=channelmap{aa};
                wid=dim(1,1);
                len=dim(1,2);
                
                maxch = 0;
                for rr=1:nrrecs
                    for yy=1:wid
                        for xx=1:len
                            thischannel=map(yy,xx);
                            
                            nrch=sum(NO{1,rr}.channelID==thischannel);
                            if nrch>maxch
                                maxch=nrch;
                            end
                            
                        end
                    end
                end
                
                MAT=nan(wid,len,nrrecs,maxch);
                
                for ee=1:nrEpochs
                    BAS{ee,aa}=MAT;
                end
                
            end %end for

            for aa=1:nrArrays
                dim=dimensions{aa};
                map=channelmap{aa};
                wid=dim(1,1);
                len=dim(1,2);

                for ee=1:nrEpochs 

                    MAT=BAS{ee,aa};
                    maxch=size(MAT,4); 
                    
                    for rr=1:nrrecs
                        for yy=1:wid
                            for xx=1:len

                                thischannel=map(yy,xx);
                                nIDs=find(NO{1,rr}.channelID==thischannel,maxch,'first');
                                
                                for nn=1:numel(nIDs)
                                    nID=nIDs(nn);
                                
                                    S=STAT{rr};
                                    
                                    MAT(yy,xx,rr,nn)=S.anova1pval{1,group}(nID,ee)<S.anova1alpha{1,4}; % check if the neuron on this channel is tuned in this epoch/recording
                                    
                                end
                            end
                        end
                    end

                    BAS{ee,aa}=MAT;


                end
            end
            
    case 'information' % assign information coding of neuron to location 
            if isnumeric(group) 
                for ii=1:nrrecs
                    N=STAT{ii};
                    if isempty(N.data(1,group))
                        error('Group not available.');
                    end
                end
            else
                group=groupname2groupid(group);  
            end
           
            ep=nan(1,nrrecs);
            for nn=1:nrrecs
                N=STAT{1,nn};
                ep(nn)=size(N.epochs{1,group},2);
                epochs=N.epochs{group};
            end

            if min(ep)~=max(ep)
                error('Data sets have different number of epochs.');
            else
                nrEpochs=min(ep);
            end
            
            
            BAS=cell(nrEpochs,nrArrays); % create basis array
            
            % find the most cells detected on a channel on all arrays and
            % recordings. this info is used for allocation of memory.
            
            for aa=1:nrArrays
                dim=dimensions{aa};
                map=channelmap{aa};
                wid=dim(1,1);
                len=dim(1,2);
                
                maxch = 0;
                for rr=1:nrrecs
                    for yy=1:wid
                        for xx=1:len
                            thischannel=map(yy,xx);
                            
                            nrch=sum(NO{1,rr}.channelID==thischannel);
                            if nrch>maxch
                                maxch=nrch;
                            end
                            
                        end
                    end
                end
                
                MAT=nan(wid,len,nrrecs,maxch);
                
                for ee=1:nrEpochs
                    BAS{ee,aa}=MAT;
                end
                
            end %end nr Arrays
            
            
            for aa=1:nrArrays
                dim=dimensions{aa};
                map=channelmap{aa};
                wid=dim(1,1);
                len=dim(1,2);

                for ee=1:nrEpochs 
                    
                    MAT=BAS{ee,aa};
                    maxch=size(MAT,4); % 4th dimension provides the maximum number of cells/channel/recording found on the array
                    
                    for rr=1:nrrecs
                        for yy=1:wid
                            for xx=1:len

                                thischannel=map(yy,xx);
                                nIDs=find(NO{1,rr}.channelID==thischannel,maxch,'first');
                                
                                for nn=1:numel(nIDs)
                                    
                                    nID=nIDs(nn);
                                    
                                    if nID==99 && ee==2
                                        stop=1;
                                    end
                                    
                                    
                                    S_is=squeeze(STAT{rr}.crossanova1{1,group}{nID,1}(ee,:,:));
                                    S_100=ones(size(S_is)); % significant difference between all conditions used as a references
                                    
                                    MAT(yy,xx,rr,nn)=sum(triu(S_is))/sum(triu(S_100)); % 0... no conditions can be distinguished, 1... all conditions are significantly different.
                                    
                                end

                            end
                        end     
                    end

                    BAS{ee,aa}=MAT;

                end
            end        
        
        
        
        
    case 'shapesize'
            ep=nan(1,nrrecs);
            for nn=1:nrrecs
                N=STAT{1,nn};
                ep(nn)=size(N.userData1,2);
                epochs=N.userData1{end,2};
            end

            if min(ep)~=max(ep)
                error('Data sets have different number of epochs.');
            else
                nrEpochs=min(ep);
            end
           if isnumeric(group)
                for ii=1:nrrecs
                    N=STAT{ii};
                    if isempty(N.userData2(1,group))
                        error('Group not available.');
                    end
                end
           else
                group=groupname2groupid(group);  
           end
  
            BAS=cell(nrEpochs,nrArrays); % create basis array

            for aa=1:nrArrays
                dim=dimensions{aa};
                map=channelmap{aa};
                wid=dim(1,1);
                len=dim(1,2);

                for ee=1:nrEpochs 

                    MAT=nan(wid,len,nrrecs);
                    for rr=1:nrrecs
                        N=STAT{rr};
                        channelID=N.channelID;
                        tuned=N.userData3{1,group}{9,1}{1,3};
                        epochtuned=tuned(:,ee); % get cells that are tuned in this epoch
                        tuned_channels=channelID(epochtuned);

                        thisrec=zeros(wid,len);
                        for ii=1:length(tuned_channels)
                             thisrec(map==tuned_channels(ii))=thisrec(map==tuned_channels(ii))+1;
                        end  

                        MAT(:,:,rr)=thisrec;
                    end

                    BAS{ee,aa}=MAT;


                end
            end
        
           
    case 'celltype'  % locate recorded single and multiunits
        ee=1; % in this case, there are not multiple epochs to analyze
        nrEpochs=1;
        group=[];
        epochs={''};
        for ii=1:nrrecs
            N=STAT{ii};
            if isempty(N.neuronType)
                error('Neuon type not available.');
            end
        end

        BAS=cell(ee,nrArrays); % create basis array

        for aa=1:nrArrays
            dim=dimensions{aa};
            map=channelmap{aa};
            wid=dim(1,1);
            len=dim(1,2);

            

            MAT=nan(wid,len,nrrecs);
            for rr=1:nrrecs
                N=STAT{rr};
                channelID=N.channelID;
                
                % find neurons with this criteria
                nrunits=numel(N.neuronID);
                neuronType=N.neuronType';

                nropt=size(typename,1);
                nrsp =size(typename,2)-1;
                mask4=false(nropt,nrunits);
                for yy=1:nropt
                    mask1=strcmpi({neuronType{:,1}},typename{yy,1});
                    
                    if nrsp>=1
                        mask2=false(nrsp,nrunits);

                        for ss=1:nrsp
                            mask2(ss,:)=strcmpi({neuronType{:,2}},typename{yy,ss+1}) & mask1;
                        end

                        mask2=logical(sum(mask2,1));
                        mask4(yy,:)= mask2;
                    else 
                        mask4(yy,:)=mask1;
                    end

                end
                mask5=logical(sum(mask4,1));
                
                sel_channels=channelID(mask5);

                thisrec=zeros(wid,len);
                for ii=1:length(sel_channels)
                     thisrec(map==sel_channels(ii))=thisrec(map==sel_channels(ii))+1;
                end  

                MAT(:,:,rr)=thisrec;
            end

            BAS{ee,aa}=MAT;


        end

    case 'single' % locate single units
    case 'partner' % locate partner neurons
    case 'mirror' % locate mirror neurons
    
        
        
        
    case 'visual'
    case 'motor'
    case 'visuo-motor'
    otherwise
        error('Specification unknow.')
end
        
        
  % ------------------- AVERAGE ALONG CHANNELS AND RECORDINGS -------------      
switch average
    case 'logic'
      for ee=1:nrEpochs
          for aa=1:nrArrays
              thisarray=BAS{ee,aa};
              thisarray=sum(thisarray,3);
              thisarray(thisarray>=1)=1;

              BAS{ee,aa}=thisarray;
          end
      end
    case 'mean'
      for ee=1:nrEpochs
          for aa=1:nrArrays
              thisarray=BAS{ee,aa};
              thisarray=mean(thisarray,3);
              BAS{ee,aa}=thisarray;
          end
      end
    case 'sum'
      for ee=1:nrEpochs
          for aa=1:nrArrays

              thisarray=BAS{ee,aa};
              
              thisarray(isnan(thisarray))=0;
          
              thisarray=sum(thisarray,4);
              
              thisarray=sum(thisarray,3);
              
              BAS{ee,aa}=thisarray;
          end
      end
    case 'max'
        for ee=1:nrEpochs
            for aa=1:nrArrays
                
                thisarray=BAS{ee,aa};
                thisarray(isnan(thisarray))=0;

                thisarray=max(thisarray,[],4);

                thisarray=max(thisarray,[],3);

                BAS{ee,aa}=thisarray;

            end
        end
      
      
  otherwise
end
        
    
% ----------------------- CREATE MASK ON ARRAY ----------------------------


switch lower(mask)
    case 'unit'
        % Searches if there were neurons recorded on every single electrode
        % if on an electrode at least one neuron has been recorded over all
        % recording sessions, this electorde position are set to valid.
        % Position on were never neurons were recorded were set ton NAN.
        for aa=1:nrArrays
            dim=dimensions{aa};
            map=channelmap{aa};
            wid=dim(1,1);
            len=dim(1,2);
            
            thismask=zeros(wid,len,nrrecs);
            for rr=1:nrrecs
                N=NO{rr};
                channelID=N.channelID;

                for ii=1:length(channelID)
                     [row,col]=find(map==channelID(ii),1,'first');
                     if ~isempty(row)
                        thismask(row,col,rr)=thismask(row,col,rr)+1;
                     end
                end  
            end
            
            thismask=sum(thismask,3); % sum all units on this position
            thismask=thismask<1;
            
            for ee=1:nrEpochs
            
                arr=BAS{ee,aa};
                arr(thismask)=NaN;
                BAS{ee,aa}=arr;
            end


        end
        case 'none'
        
    otherwise
        error('Specification unknown.');
end



plotstruct.data=BAS;
plotstruct.group=group;
plotstruct.specification=specification;
plotstruct.average=average;
plotstruct.mask=mask;
plotstruct.epochs=epochs;






